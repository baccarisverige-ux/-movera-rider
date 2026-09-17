import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/realtime/realtime_connection.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/finding_driver/domain/driver_eta.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

/// Mock matching transport. Assignment is an event, not a widget timer.
class MockRideRealtime implements RideRealtime {
  MockRideRealtime({
    this.assignAfter = const Duration(seconds: 25),
    this.boardAfter = const Duration(seconds: 8),
    this.tripTick = const Duration(seconds: 3),
    this.tripTicks = 6,
    RealtimeConnection? connection,
    this.api,
  }) : connection = connection ?? RealtimeConnection();

  final Duration assignAfter;

  /// Once the driver is waiting at pickup, how long before the rider boards.
  final Duration boardAfter;

  /// Cadence and length of the trip itself, so a ride can actually finish.
  final Duration tripTick;
  final int tripTicks;
  final RealtimeConnection connection;
  final ApiClient? api;
  final _controller = StreamController<RideRealtimeEvent>.broadcast();
  Timer? _assign;
  Timer? _gps;
  Timer? _board;
  Timer? _trip;
  int _tripTicksDone = 0;
  String? _rideId;
  int _sequence = 0;
  bool cancelled = false;
  bool disposed = false;
  bool held = false;
  bool _assignmentInFlight = false;
  RideStatus lastStatus = RideStatus.findingDriver;
  MatchedDriver? lastDriver;
  double? lastLat;
  double? lastLng;
  DateTime? lastLocationAt;
  double? _pickupLat;
  double? _pickupLng;
  double _progress = 0;

  @override
  Stream<RideRealtimeEvent> subscribe(String rideId) {
    if (_rideId == rideId && !disposed && !cancelled) {
      return _controller.stream;
    }
    _assign?.cancel();
    _gps?.cancel();
    _board?.cancel();
    _trip?.cancel();
    _tripTicksDone = 0;
    cancelled = false;
    disposed = false;
    held = false;
    _assignmentInFlight = false;
    _rideId = rideId;
    _sequence = 0;
    lastStatus = RideStatus.findingDriver;
    lastDriver = null;
    lastLat = null;
    lastLng = null;
    lastLocationAt = null;
    _progress = 0;
    connection.markConnected();
    _emit(RideStatus.findingDriver);
    _assign = Timer(assignAfter, () {
      if (cancelled || disposed || held || _rideId != rideId) return;
      assignNow();
    });
    return _controller.stream;
  }

  void holdAssignment() {
    held = true;
    _assign?.cancel();
    _assign = null;
  }

  void assignNow() {
    unawaited(_assignNow());
  }

  Future<void> _assignNow() async {
    final rideId = _rideId;
    if (cancelled ||
        disposed ||
        held ||
        rideId == null ||
        lastStatus.isTerminal ||
        _assignmentInFlight) {
      return;
    }
    if (lastStatus.isMatched) return;

    _assignmentInFlight = true;
    _assign?.cancel();
    _assign = null;
    _pickupLat ??= 59.3293;
    _pickupLng ??= 18.0686;
    lastLat ??= _pickupLat! + 0.0072;
    lastLng ??= _pickupLng! - 0.0048;
    lastLocationAt = DateTime.now();

    await _persistAssignment(rideId);

    if (cancelled || disposed || held || _rideId != rideId) {
      _assignmentInFlight = false;
      return;
    }

    lastStatus = RideStatus.driverAssigned;
    _assignmentInFlight = false;
    _emit(RideStatus.driverAssigned);
    _startGps();
    unawaited(_hydratePickup());
  }

  void emit(
    RideStatus status, {
    int? sequence,
    MatchedDriver? driver,
    double? latitude,
    double? longitude,
    int? etaSeconds,
  }) {
    if (_rideId == null || disposed || cancelled || lastStatus.isTerminal) {
      return;
    }
    _sequence = sequence ?? _sequence + 1;
    lastStatus = status;
    if (driver != null) lastDriver = driver;
    if (latitude != null) lastLat = latitude;
    if (longitude != null) lastLng = longitude;
    if (latitude != null || longitude != null) lastLocationAt = DateTime.now();
    _controller.add(
      RideRealtimeEvent(
        rideId: _rideId!,
        status: status,
        sequence: _sequence,
        at: DateTime.now(),
        driver: lastDriver,
        latitude: lastLat,
        longitude: lastLng,
        etaSeconds: etaSeconds,
        locationAt: lastLocationAt,
      ),
    );
    if (status.isTerminal) {
      cancelled = true;
      _stopMotion();
      unsubscribe();
    }
  }

  void _emit(RideStatus status) {
    final eta = _etaSeconds();
    emit(status, etaSeconds: eta);
  }

  Future<void> _hydratePickup() async {
    final pickup = await _pickup();
    _pickupLat = pickup.$1;
    _pickupLng = pickup.$2;
  }

  void _startGps() {
    _gps?.cancel();
    _gps = Timer.periodic(const Duration(seconds: 3), (_) {
      if (cancelled || disposed || !lastStatus.isMatched) return;
      _progress = min(1, _progress + 0.12);
      final pickupLat = _pickupLat;
      final pickupLng = _pickupLng;
      if (pickupLat == null ||
          pickupLng == null ||
          lastLat == null ||
          lastLng == null) {
        return;
      }
      lastLat = lastLat! + (pickupLat - lastLat!) * 0.18;
      lastLng = lastLng! + (pickupLng - lastLng!) * 0.18;
      lastLocationAt = DateTime.now();
      var status = RideStatus.driverArriving;
      final distance = DriverEta.metersBetween(
        lastLat!,
        lastLng!,
        pickupLat,
        pickupLng,
      );
      if (distance < 50) {
        status = RideStatus.driverWaiting;
      }
      lastStatus = status;
      _emit(status);
      if (status == RideStatus.driverWaiting) {
        _gps?.cancel();
        _gps = null;
        _startTrip();
      }
    });
  }

  /// Tests drive arrival directly: the GPS walk depends on real pickup
  /// coordinates fetched over the mock API, which unit tests do not stand up.
  @visibleForTesting
  void markArrivedForTest() {
    if (cancelled || disposed || _rideId == null || lastStatus.isTerminal) {
      return;
    }
    lastStatus = RideStatus.driverWaiting;
    _emit(RideStatus.driverWaiting);
    _startTrip();
  }

  /// The driver is at pickup; carry the ride through to completion so the
  /// rider reaches the finished-ride screen instead of waiting forever.
  void _startTrip() {
    _board?.cancel();
    _board = Timer(boardAfter, () {
      if (cancelled || disposed || _rideId == null) return;
      lastStatus = RideStatus.tripStarted;
      _emit(RideStatus.tripStarted);
      _trip?.cancel();
      _tripTicksDone = 0;
      _trip = Timer.periodic(tripTick, (timer) {
        if (cancelled || disposed || _rideId == null) {
          timer.cancel();
          return;
        }
        _tripTicksDone += 1;
        if (_tripTicksDone >= tripTicks) {
          timer.cancel();
          lastStatus = RideStatus.tripCompleted;
          _emit(RideStatus.tripCompleted);
          return;
        }
        lastStatus = RideStatus.tripInProgress;
        _emit(RideStatus.tripInProgress);
      });
    });
  }

  int? _etaSeconds() {
    final lat = lastLat;
    final lng = lastLng;
    final pickupLat = _pickupLat;
    final pickupLng = _pickupLng;
    if (lat == null || lng == null || pickupLat == null || pickupLng == null) {
      return null;
    }
    return DriverEta.secondsForDistance(
      DriverEta.metersBetween(lat, lng, pickupLat, pickupLng),
    );
  }

  Future<(double, double)> _pickup() async {
    final client = api;
    final id = _rideId;
    if (client != null && id != null) {
      try {
        final json = await client.get('/api/v1/rides/$id');
        final ride = json['ride'];
        if (ride is Map) {
          final lat = (ride['pickupLat'] as num?)?.toDouble();
          final lng = (ride['pickupLng'] as num?)?.toDouble();
          if (lat != null && lng != null) return (lat, lng);
        }
      } catch (_) {}
    }
    return (59.3293, 18.0686);
  }

  Future<void> _persistAssignment(String rideId) async {
    final client = api;
    if (client == null) return;
    try {
      await client.post(
        '/api/v1/rides/$rideId/status',
        body: {
          'status': RideStatus.driverAssigned.name,
          'driver': lastDriver?.toJson(),
          'lat': lastLat,
          'lng': lastLng,
        },
      );
    } catch (_) {}
  }

  @override
  Future<void> reconnectAndResync(String rideId) async {
    connection.state = RealtimeState.reconnecting;
    await Future<void>.delayed(connection.nextBackoff());
    connection.markConnected();
    var status = lastStatus;
    final client = api;
    if (client != null) {
      try {
        final json = await client.get('/api/v1/rides/$rideId');
        final raw = json['ride'];
        if (raw is Map && raw['status'] is String) {
          status = RideStatus.values.firstWhere(
            (value) => value.name == raw['status'],
            orElse: () => status,
          );
          lastDriver =
              MatchedDriver.fromJson(
                raw['driver'] is Map
                    ? Map<String, dynamic>.from(raw['driver'] as Map)
                    : null,
              ) ??
              lastDriver;
        }
      } catch (_) {}
    }
    lastStatus = status;
    if (!cancelled && !disposed) _emit(status);
  }

  @override
  void unsubscribe() {
    _assign?.cancel();
    _assign = null;
  }

  @override
  void cancelRide() {
    cancelled = true;
    lastStatus = RideStatus.cancelledByRider;
    _stopMotion();
    unsubscribe();
  }

  /// Every timer that advances a ride, stopped together — a cancelled or
  /// disposed ride must not keep driving itself to completion.
  void _stopMotion() {
    _gps?.cancel();
    _gps = null;
    _board?.cancel();
    _board = null;
    _trip?.cancel();
    _trip = null;
  }

  @override
  void dispose() {
    disposed = true;
    cancelled = true;
    _stopMotion();
    unsubscribe();
    if (!_controller.isClosed) _controller.close();
  }
}
