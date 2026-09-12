import 'dart:async';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/debug/web_qa_hooks.dart';
import 'package:movera_rider/core/location/app_geocoding.dart';
import 'package:movera_rider/core/location/location_point.dart';
import 'package:movera_rider/core/location/location_repository.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/motion/bearing.dart';
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
    Future<bool> Function()? startCompass,
    double? Function()? readCompass,
    void Function()? stopCompass,
  })  : _startCompass = startCompass ?? heading_service.startHeadingTracking,
        _readCompass = readCompass ?? heading_service.currentHeading,
        _stopCompass = stopCompass ?? heading_service.stopHeadingTracking;

  final LocationRepository location;
  final AppGeocoding geocoding;
  final MotionEngine motion;
  final Future<bool> Function() _startCompass;
  final double? Function() _readCompass;
  final void Function() _stopCompass;

  final StaleGuard _geoGuard = StaleGuard();
  StreamSubscription<Position>? _positionSub;
  Timer? _headingTimer;
  Timer? _pulseTimer;
  bool Function()? _headingMounted;
  void Function(double heading)? _onHeading;
  Future<bool>? _headingStartInFlight;
  bool _compassStarted = false;
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
          reportPuckHeading(heading, compass: false);
        }
        onFix(latLng, heading);
      },
    );
  }

  /// Requests compass permission, then polls heading. Returns whether the
  /// compass actually started. GPS course remains the fallback if this fails.
  Future<bool> startHeading({
    required bool Function() isMounted,
    required void Function(double heading) onHeading,
  }) async {
    _headingMounted = isMounted;
    _onHeading = onHeading;
    final granted = await _ensureCompassStarted();
    _ensureHeadingPoller();
    return granted;
  }

  Future<bool> _ensureCompassStarted() {
    if (_compassStarted) return Future.value(true);
    return _headingStartInFlight ??= _openCompass();
  }

  Future<bool> _openCompass() async {
    try {
      final granted = await _startCompass();
      _compassStarted = granted;
      if (!granted) _headingStartInFlight = null;
      return granted;
    } catch (_) {
      _compassStarted = false;
      _headingStartInFlight = null;
      return false;
    }
  }

  void _ensureHeadingPoller() {
    if (_headingTimer != null) return;
    _headingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      pollHeading();
    });
  }

  /// Applies one compass sample. Public for tests so heading can be verified
  /// without waiting on a real timer.
  @visibleForTesting
  void pollHeading() {
    final mounted = _headingMounted;
    if (mounted != null && !mounted()) return;
    final next = _readCompass();
    if (next == null || !next.isFinite) return;
    final blended = blendHeading(heading, next);
    if ((blended - heading).abs() < 0.01 && hasCompassHeading) return;
    hasCompassHeading = true;
    heading = blended;
    reportPuckHeading(heading, compass: true);
    _onHeading?.call(heading);
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
      reportPuckHeading(heading, compass: false);
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

  Future<void> bindLiveLocation({
    required bool Function() isMounted,
    required void Function(LatLng latLng, double heading) onFix,
    required void Function(double heading) onHeading,
    required void Function() onPulse,
  }) async {
    startTracking(isMounted: isMounted, onFix: onFix);
    startPulse(isMounted: isMounted, onTick: onPulse);
    await startHeading(isMounted: isMounted, onHeading: onHeading);
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
    _headingTimer = null;
    _pulseTimer?.cancel();
    _geoGuard.dispose();
    _stopCompass();
    _compassStarted = false;
    _headingStartInFlight = null;
    hasCompassHeading = false;
  }
}
