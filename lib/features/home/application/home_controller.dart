import 'dart:async';
import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/debug/web_qa_hooks.dart';
import 'package:movera_rider/core/location/geocoding_repository.dart';
import 'package:movera_rider/core/location/location_point.dart';
import 'package:movera_rider/core/location/location_repository.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/motion/bearing.dart';
import 'package:movera_rider/core/motion/motion_engine.dart';
import 'package:movera_rider/core/utils/stale_guard.dart';
import 'package:movera_rider/shared/services/device_heading.dart'
    as heading_service;

enum HomeLocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

enum HomeLocationState {
  initializing,
  permissionRequired,
  servicesDisabled,
  acquiringFix,
  live,
  temporarilyUnavailable,
  recovering,
}

class DetectedLocation {
  const DetectedLocation({
    required this.target,
    required this.address,
    required this.heading,
    this.failure,
  });

  final LatLng? target;
  final String address;
  final double heading;
  final HomeLocationFailure? failure;

  bool get denied =>
      failure == HomeLocationFailure.permissionDenied ||
      failure == HomeLocationFailure.permissionDeniedForever;
  bool get unavailable => failure != null;
}

/// Owns GPS, motion, heading blend, reverse geocode, and map overlay sets.
/// Home only paints. Overlay changes notify so the map layer can rebuild
/// without the rest of the Home tree.
class HomeLocationController extends ChangeNotifier {
  HomeLocationController({
    required this.location,
    required this.geocoding,
    required this.motion,
    Future<bool> Function()? startCompass,
    double? Function()? readCompass,
    void Function()? stopCompass,
  }) : _startCompass = startCompass ?? heading_service.startHeadingTracking,
       _readCompass = readCompass ?? heading_service.currentHeading,
       _stopCompass = stopCompass ?? heading_service.stopHeadingTracking;

  final LocationRepository location;
  final GeocodingRepository geocoding;
  final MotionEngine motion;
  final Future<bool> Function() _startCompass;
  final double? Function() _readCompass;
  final void Function() _stopCompass;

  final StaleGuard _normaliseGuard = StaleGuard();
  final StaleGuard _pointGuard = StaleGuard();
  final StaleGuard _placeGuard = StaleGuard();
  final StaleGuard _detectGuard = StaleGuard();
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
  bool _livePaused = false;
  HomeLocationState state = HomeLocationState.initializing;
  Set<Marker> markers = {};
  Set<Circle> locationCircles = {};
  Set<Polygon> locationDirection = {};

  /// Opens one staleness scope for every address normalisation belonging to a
  /// single user action. Concurrent calls share one generation so siblings do
  /// not invalidate each other, while a newer route confirmation invalidates
  /// the whole older batch.
  int beginNormalisationBatch() => _normaliseGuard.next();

  Future<String> normaliseAddress(String input, {int? generation}) async {
    final clean = input.trim();
    if (clean.isEmpty || clean == 'Current location') return clean;
    final scope = generation ?? _normaliseGuard.next();
    final result = await geocoding.forward(clean);
    if (!_normaliseGuard.isCurrent(scope)) return clean;
    return result?.address.trim().isNotEmpty == true
        ? result!.address.trim()
        : clean;
  }

  Future<LatLng?> geocodeLatLng(String address) async {
    final generation = _pointGuard.next();
    final result = await geocoding.forward(address);
    if (!_pointGuard.isCurrent(generation) || result == null) return null;
    return LatLng(result.point.latitude, result.point.longitude);
  }

  Future<({LatLng point, String address})?> geocodePlace(String address) async {
    final generation = _placeGuard.next();
    final result = await geocoding.forward(address);
    if (!_placeGuard.isCurrent(generation) || result == null) return null;
    return (
      point: LatLng(result.point.latitude, result.point.longitude),
      address: result.address.trim().isNotEmpty
          ? result.address.trim()
          : address,
    );
  }

  void _setState(HomeLocationState next) {
    if (state == next) return;
    state = next;
    notifyListeners();
  }

  Future<DetectedLocation> detectCurrent() async {
    _setState(HomeLocationState.initializing);
    try {
      if (!await location.isLocationServiceEnabled()) {
        _setState(HomeLocationState.servicesDisabled);
        return const DetectedLocation(
          target: null,
          address: 'Current location',
          heading: 0,
          failure: HomeLocationFailure.servicesDisabled,
        );
      }
      var permission = await location.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await location.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _setState(HomeLocationState.permissionRequired);
        return const DetectedLocation(
          target: null,
          address: 'Current location',
          heading: 0,
          failure: HomeLocationFailure.permissionDeniedForever,
        );
      }
      if (permission == LocationPermission.denied) {
        _setState(HomeLocationState.permissionRequired);
        return const DetectedLocation(
          target: null,
          address: 'Current location',
          heading: 0,
          failure: HomeLocationFailure.permissionDenied,
        );
      }
      _setState(HomeLocationState.acquiringFix);
      final position = await location.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final generation = _detectGuard.next();
      String? detected;
      try {
        detected = await geocoding.reverse(
          GeoPoint(position.latitude, position.longitude),
        );
      } catch (_) {
        // Address enrichment must never invalidate an already acquired GPS fix.
        // The rider puck and live stream are coordinate-driven, not geocoder-driven.
        detected = null;
      }
      if (!_detectGuard.isCurrent(generation)) {
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
      _setState(HomeLocationState.live);
      return DetectedLocation(
        target: LatLng(position.latitude, position.longitude),
        address: address,
        heading: heading,
      );
    } catch (_) {
      _setState(HomeLocationState.temporarilyUnavailable);
      return const DetectedLocation(
        target: null,
        address: 'Current location',
        heading: 0,
        failure: HomeLocationFailure.unavailable,
      );
    }
  }

  void startTracking({
    required bool Function() isMounted,
    required void Function(LatLng latLng, double heading) onFix,
  }) {
    _positionSub?.cancel();
    final settings = LocationSettings(
      accuracy: kIsWeb
          ? LocationAccuracy.high
          : LocationAccuracy.bestForNavigation,
      distanceFilter: kIsWeb ? 20 : 8,
    );
    _positionSub = location
        .getPositionStream(locationSettings: settings)
        .listen(
          (position) {
            if (!isMounted() || _livePaused) return;
            _setState(HomeLocationState.live);
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
          onError: (Object _) {
            _setState(HomeLocationState.temporarilyUnavailable);
            _positionSub?.cancel();
            _positionSub = null;
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
    _headingTimer = Timer.periodic(
      Duration(milliseconds: kIsWeb ? 250 : 100),
      (_) {
        if (_livePaused) return;
        pollHeading();
      },
    );
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
      if (!isMounted() || _livePaused) return;
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
    notifyListeners();
  }

  void paintUserPuck({
    required LatLng target,
    required BitmapDescriptor icon,
    required double heading,
  }) {
    if (_livePaused) return;
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
        zIndexInt: 20,
      ),
    };
    notifyListeners();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _headingTimer?.cancel();
    _headingTimer = null;
    _pulseTimer?.cancel();
    _normaliseGuard.dispose();
    _pointGuard.dispose();
    _placeGuard.dispose();
    _detectGuard.dispose();
    _stopCompass();
    _compassStarted = false;
    _headingStartInFlight = null;
    hasCompassHeading = false;
    super.dispose();
  }

  void pauseLiveUpdates() {
    _livePaused = true;
  }

  void resumeLiveUpdates() {
    _livePaused = false;
  }

  void recoverLiveLocation({
    required bool Function() isMounted,
    required void Function(LatLng latLng, double heading) onFix,
  }) {
    if (_livePaused) return;
    _setState(HomeLocationState.recovering);
    startTracking(isMounted: isMounted, onFix: onFix);
  }
}
