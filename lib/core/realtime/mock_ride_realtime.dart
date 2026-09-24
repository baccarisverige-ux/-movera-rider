import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/realtime/mock_driver_pool.dart';
import 'package:movera_rider/core/realtime/realtime_connection.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/finding_driver/domain/driver_eta.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

/// Mock matching transport. Assignment is an event, not a widget timer.
class MockRideRealtime implements RideRealtime {
  @override
  bool get supportsRiderSignals => true;

  MockRideRealtime({
    this.assignAfter = const Duration(seconds: 25),
    this.boardAfter = const Duration(seconds: 8),
    this.tripTick = const Duration(seconds: 3),
    this.tripTicks = 6,
    this.paymentProcessingAfter = const Duration(milliseconds: 500),
    this.paymentFinalizedAfter = const Duration(milliseconds: 500),
    this.ratingPendingAfter = const Duration(milliseconds: 300),
    RealtimeConnection? connection,
    this.api,
  }) : connection = connection ?? RealtimeConnection();

  final Duration assignAfter;

  /// Once the driver is waiting at pickup, how long before the rider boards.
  final Duration boardAfter;

  /// Cadence and length of the trip itself, so a ride can actually finish.
  final Duration tripTick;
  final int tripTicks;

  /// Demo-only post-trip cadence. Production replaces MockRideRealtime with
  /// the real transport, where these statuses are backend-authored.
  final Duration paymentProcessingAfter;
  final Duration paymentFinalizedAfter;
  final Duration ratingPendingAfter;

  final RealtimeConnection connection;
  final ApiClient? api;
  final _controller = StreamController<RideRealtimeEvent>.broadcast();
  Timer? _assign;
  Timer? _gps;
  Timer? _board;
  Timer? _trip;
  Timer? _paymentProcessing;
  Timer? _paymentFinalized;
  Timer? _ratingPending;
  int _tripTicksDone = 0;
  int _assignmentAttempt = 0;
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
    _paymentProcessing?.cancel();
    _paymentFinalized?.cancel();
    _ratingPending?.cancel();
    _tripTicksDone = 0;
    _assignmentAttempt = 0;
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
    // Matching is what knows the driver. Assign before persisting so the
    // stored ride, every later resync, and a restored session all agree.
    lastDriver ??= MockDriverPool.forRide(
      rideId,
      attempt: _assignmentAttempt,
    );

    await _persistAssignment(rideId);

    if (cancelled || disposed || _rideId != rideId) {
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
    RideRealtimeSignal? signal,
    String? message,
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
    final occurredAt = DateTime.now().toUtc();
    _controller.add(
      RideRealtimeEvent(
        tripId: _rideId!,
        eventId: '${_rideId!}:$_sequence:${status.name}',
        status: status,
        sequence: _sequence,
        version: _sequence,
        occurredAt: occurredAt,
        serverTime: occurredAt,
        driver: lastDriver,
        latitude: lastLat,
        longitude: lastLng,
        etaSeconds: etaSeconds,
        locationAt: lastLocationAt,
        signal: signal,
        message: message,
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
        emit(
          RideStatus.driverWaiting,
          signal: RideRealtimeSignal.driverArrived,
          message: 'Your driver has arrived at the pickup point.',
        );
        _startTrip();
      }
    });
  }

  /// The assigned driver drops the ride before pickup.
  ///
  /// The rider's ride is not over — dispatch simply looks again — so this
  /// returns to searching and offers a different driver, rather than ending
  /// the trip the way a rider's own cancellation does.
  void cancelByDriver() {
    final rideId = _rideId;
    if (rideId == null || cancelled || disposed) return;
    if (lastStatus.isCompletedSurface || lastStatus.isTerminal) return;

    _stopMotion();
    _assignmentAttempt += 1;
    lastDriver = null;
    lastLat = null;
    lastLng = null;
    lastLocationAt = null;
    _progress = 0;
    // Driver drop is a dispatch event, not a terminal ride transition.
    // Keep the rider's ride in the legal matching graph and start a fresh
    // assignment attempt without publishing cancelledByDriver -> findingDriver.
    lastStatus = RideStatus.findingDriver;
    _sequence += 1;
    final now = DateTime.now().toUtc();
    _controller.add(
      RideRealtimeEvent(
        tripId: rideId,
        eventId: '$rideId:$_sequence:${RideStatus.findingDriver.name}',
        status: RideStatus.findingDriver,
        sequence: _sequence,
        version: _sequence,
        occurredAt: now,
        serverTime: now,
      ),
    );
    _assign?.cancel();
    _assign = Timer(assignAfter, () {
      if (cancelled || disposed || held || _rideId != rideId) return;
      assignNow();
    });
  }

  /// Search again for the same ride after a driver dropped it.
  @override
  void researchAfterDriverCancel() {
    final rideId = _rideId;
    if (rideId == null || disposed) return;
    if (cancelled || lastStatus != RideStatus.findingDriver) return;
    if (_assign != null || _assignmentInFlight) return;
    _assign = Timer(assignAfter, () {
      if (cancelled || disposed || held || _rideId != rideId) return;
      assignNow();
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
    emit(
      RideStatus.driverWaiting,
      signal: RideRealtimeSignal.driverArrived,
      message: 'Your driver has arrived at the pickup point.',
    );
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
          _startPostTripFlow();
          return;
        }
        lastStatus = RideStatus.tripInProgress;
        _emit(RideStatus.tripInProgress);
      });
    });
  }

  void _startPostTripFlow() {
    _paymentProcessing?.cancel();
    _paymentFinalized?.cancel();
    _ratingPending?.cancel();

    _paymentProcessing = Timer(paymentProcessingAfter, () {
      if (cancelled || disposed || _rideId == null) return;
      lastStatus = RideStatus.paymentProcessing;
      _emit(RideStatus.paymentProcessing);

      _paymentFinalized = Timer(paymentFinalizedAfter, () {
        if (cancelled || disposed || _rideId == null) return;
        lastStatus = RideStatus.paymentFinalized;
        _emit(RideStatus.paymentFinalized);

        _ratingPending = Timer(ratingPendingAfter, () {
          if (cancelled || disposed || _rideId == null) return;
          lastStatus = RideStatus.ratingPending;
          _emit(RideStatus.ratingPending);
        });
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
  Future<void> sendSignal({
    required String rideId,
    required RideRealtimeSignal signal,
    String? message,
  }) async {
    if (_rideId != rideId || disposed || cancelled) return;
    emit(
      lastStatus,
      signal: signal,
      message: message,
    );
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
    // Deliver the authoritative resync status before committing it to
    // lastStatus. emit() guards against events after a terminal status; writing
    // the incoming terminal status first would therefore make the event block
    // itself and disappear from the Rider stream.
    if (!cancelled && !disposed) {
      _emit(status);
    }
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
    _paymentProcessing?.cancel();
    _paymentProcessing = null;
    _paymentFinalized?.cancel();
    _paymentFinalized = null;
    _ratingPending?.cancel();
    _ratingPending = null;
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
