import 'dart:async';
import 'dart:ui' show Offset;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/location/app_geocoding.dart';
import 'package:movera_rider/core/location/location_point.dart';
import 'package:movera_rider/core/location/location_repository.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/motion/motion_engine.dart';
import 'package:movera_rider/core/utils/stale_guard.dart';
import 'package:movera_rider/shared/services/device_heading.dart' as heading_service;

class DetectedLocation {
  const DetectedLocation({
    required this.target,
    required this.address,
    required this.heading,
    this.denied = false,
  });

  final LatLng? target;
  final String address;
  final double heading;
  final bool denied;
}

/// Owns GPS, motion, heading blend, reverse geocode, and map overlay sets.
/// Home only paints.
class HomeLocationController {
  HomeLocationController({
    required this.location,
    required this.geocoding,
    required this.motion,
  });

  final LocationRepository location;
  final AppGeocoding geocoding;
  final MotionEngine motion;

  final StaleGuard _geoGuard = StaleGuard();
  StreamSubscription<Position>? _positionSub;
  Timer? _headingTimer;
  Timer? _pulseTimer;
  bool hasCompassHeading = false;
  double heading = 0;
  double lastMapZoom = 13.0;
  LatLng lastMapTarget = const LatLng(59.3293, 18.0686);
  bool pulseExpanded = false;
  Set<Marker> markers = {};
  Set<Circle> locationCircles = {};
  Set<Polygon> locationDirection = {};

  Future<String> normaliseAddress(String input) async {
    final clean = input.trim();
    if (clean.isEmpty || clean == 'Current location') return clean;
    final generation = _geoGuard.next();
    final result = await geocoding.geocodeAddress(clean);
    if (!_geoGuard.isCurrent(generation)) return clean;
    return result?.address.trim().isNotEmpty == true
        ? result!.address.trim()
        : clean;
  }

  Future<LatLng?> geocodeLatLng(String address) async {
    final generation = _geoGuard.next();
    final result = await geocoding.geocodeAddress(address);
    if (!_geoGuard.isCurrent(generation) || result == null) return null;
    return LatLng(result.latitude, result.longitude);
  }

  Future<({LatLng point, String address})?> geocodePlace(String address) async {
    final generation = _geoGuard.next();
    final result = await geocoding.geocodeAddress(address);
    if (!_geoGuard.isCurrent(generation) || result == null) return null;
    return (
      point: LatLng(result.latitude, result.longitude),
      address: result.address.trim().isNotEmpty ? result.address.trim() : address,
    );
  }

  Future<DetectedLocation> detectCurrent() async {
    var permission = await location.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await location.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return const DetectedLocation(
        target: null,
        address: 'Current location',
        heading: 0,
        denied: true,
      );
    }
    final position = await location.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    final generation = _geoGuard.next();
    final detected = await geocoding.reverseGeocodeAddress(
      position.latitude,
      position.longitude,
    );
    if (!_geoGuard.isCurrent(generation)) {
      return DetectedLocation(
        target: LatLng(position.latitude, position.longitude),
        address: 'Current location',
        heading: position.heading.isFinite && position.heading >= 0
            ? position.heading
            : 0,
      );
    }
    final address = detected?.trim().isNotEmpty == true
        ? detected!.trim()
        : 'Current location';
    heading = position.heading.isFinite && position.heading >= 0
        ? position.heading
        : 0;
    return DetectedLocation(
      target: LatLng(position.latitude, position.longitude),
      address: address,
      heading: heading,
    );
  }

  void startTracking({
    required bool Function() isMounted,
    required void Function(LatLng latLng, double heading) onFix,
  }) {
    _positionSub?.cancel();
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );
    _positionSub = location.getPositionStream(locationSettings: settings).listen(
      (position) {
        if (!isMounted()) return;
        final pose = motion.ingest(
          LocationPoint(
            point: GeoPoint(position.latitude, position.longitude),
            timestamp: position.timestamp,
            accuracyMeters: position.accuracy,
            speedMps: position.speed,
            heading: position.heading,
          ),
        );
        final latLng = pose == null
            ? LatLng(position.latitude, position.longitude)
            : LatLng(pose.position.latitude, pose.position.longitude);
        if (!hasCompassHeading &&
            position.heading.isFinite &&
            position.heading >= 0) {
          heading = position.heading;
        }
        onFix(latLng, heading);
      },
    );
  }

  void startHeading({
    required bool Function() isMounted,
    required void Function(double heading) onHeading,
  }) {
    heading_service.startHeadingTracking();
    _headingTimer?.cancel();
    _headingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final next = heading_service.currentHeading();
      if (next == null || !next.isFinite || !isMounted()) return;
      var delta = (next - heading + 540) % 360 - 180;
      if (delta.abs() < 0.5) return;
      hasCompassHeading = true;
      heading = (heading + delta * 0.32 + 360) % 360;
      onHeading(heading);
    });
  }

  Future<LatLng?> latestFix() async {
    final position = await location.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        timeLimit: Duration(seconds: 8),
      ),
    );
    final target = LatLng(position.latitude, position.longitude);
    if (!hasCompassHeading &&
        position.heading.isFinite &&
        position.heading >= 0) {
      heading = position.heading;
    }
    return target;
  }

  void startPulse({
    required bool Function() isMounted,
    required void Function() onTick,
  }) {
    _pulseTimer?.cancel();
    pulseExpanded = false;
    onTick();
    _pulseTimer = Timer.periodic(const Duration(milliseconds: 850), (_) {
      if (!isMounted()) return;
      pulseExpanded = !pulseExpanded;
      onTick();
    });
  }

  void bindLiveLocation({
    required bool Function() isMounted,
    required void Function(LatLng latLng, double heading) onFix,
    required void Function(double heading) onHeading,
    required void Function() onPulse,
  }) {
    startTracking(isMounted: isMounted, onFix: onFix);
    startHeading(isMounted: isMounted, onHeading: onHeading);
    startPulse(isMounted: isMounted, onTick: onPulse);
  }

  void clearOverlays() {
    markers = {};
    locationCircles = {};
    locationDirection = {};
  }

  void paintUserPuck({
    required LatLng target,
    required BitmapDescriptor icon,
    required double heading,
  }) {
    locationCircles = {};
    locationDirection = {};
    markers = {
      Marker(
        markerId: const MarkerId('live_user_location'),
        position: target,
        icon: icon,
        anchor: const Offset(0.5, 0.66),
        rotation: heading,
        flat: true,
        zIndex: 20,
      ),
    };
  }

  void dispose() {
    _positionSub?.cancel();
    _headingTimer?.cancel();
    _pulseTimer?.cancel();
    _geoGuard.dispose();
  }
}
