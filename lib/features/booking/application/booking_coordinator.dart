import 'dart:convert';

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/features/booking/application/booking_attempt.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class BookingCoordinator {
  BookingCoordinator({ApiClient? api}) : _api = api;

  final ApiClient? _api;
  Future<String>? _inflight;
  BookingAttempt? _attempt;

  ApiClient get _client => _api ?? AppScope.instance.api;

  /// Lock only while the Finding UI is actually mounted.
  /// Do not treat a leftover [RideSession] status as an active search — tests
  /// and a dismissed route share the process-wide [AppScope].
  bool get _findingAlreadyActive => FindingDriverController.active != null;

  Future<String> _refuseOrExisting() {
    final id = AppScope.instance.ride.rideId;
    if (id != null) return Future<String>.value(id);
    return Future<String>.error(StateError('Finding already active'));
  }

  BookingAttempt _attemptFor(String intentKey) {
    final current = _attempt;
    if (current != null && current.matches(intentKey)) return current;
    final next = BookingAttempt(intentKey: intentKey);
    _attempt = next;
    return next;
  }

  void _releaseWhenDone(
    Future<String> started,
    BookingAttempt attempt,
  ) {
    started.then<void>(
      (_) {
        if (identical(_inflight, started)) _inflight = null;
        if (identical(_attempt, attempt)) _attempt = null;
      },
      onError: (Object _, StackTrace __) {
        // Keep the logical attempt after failure so an explicit retry of the
        // same booking intent reuses the exact same idempotency key.
        if (identical(_inflight, started)) _inflight = null;
      },
    );
  }

  Future<String> requestBooking({
    required String rideType,
    required String paymentMethod,
    String? scheduledAt,
  }) {
    if (_inflight != null) return _inflight!;
    if (scheduledAt == null && _findingAlreadyActive) {
      return _refuseOrExisting();
    }
    final intentKey = jsonEncode(<String, Object?>{
      'operation': 'requestBooking',
      'rideType': rideType,
      'paymentMethod': paymentMethod,
      'scheduledAt': scheduledAt,
    });
    final attempt = _attemptFor(intentKey);
    final started = _requestBooking(
      rideType: rideType,
      paymentMethod: paymentMethod,
      scheduledAt: scheduledAt,
      attempt: attempt,
    );
    _inflight = started;
    _releaseWhenDone(started, attempt);
    return started;
  }

  Future<String> _requestBooking({
    required String rideType,
    required String paymentMethod,
    String? scheduledAt,
    required BookingAttempt attempt,
  }) async {
    final id = attempt.idempotencyKey;
    final json = await _client.post(
      '/api/v1/rides',
      body: {
        'rideType': rideType,
        'paymentMethod': paymentMethod,
        'scheduledAt': scheduledAt,
      },
      idempotencyKey: id,
    );
    final rideId = (json['ride'] is Map ? json['ride']['id'] : id).toString();
    AppScope.instance.ride.restoreFromBackend(
      RideStatus.bookingRequested,
      id: rideId,
    );
    Analytics.bookingSubmitted(rideId: rideId);
    if (scheduledAt == null) {
      AppScope.instance.ride.restoreFromBackend(
        RideStatus.findingDriver,
        id: rideId,
      );
    }
    return rideId;
  }

  Future<String> submitFinding({
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    required String rideType,
    required double price,
    required String paymentMethod,
    RideNotes notes = RideNotes.empty,
  }) {
    if (_inflight != null) return _inflight!;
    if (_findingAlreadyActive) {
      return _refuseOrExisting();
    }
    final intentKey = jsonEncode(<String, Object?>{
      'operation': 'submitFinding',
      'pickupAddress': pickupAddress,
      'destinationAddress': destinationAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'rideType': rideType,
      'price': price,
      'paymentMethod': paymentMethod,
      'notes': notes.toJson(),
    });
    final attempt = _attemptFor(intentKey);
    final started = _submitFinding(
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      rideType: rideType,
      price: price,
      paymentMethod: paymentMethod,
      notes: notes,
      attempt: attempt,
    );
    _inflight = started;
    _releaseWhenDone(started, attempt);
    return started;
  }

  Future<String> _submitFinding({
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    required String rideType,
    required double price,
    required String paymentMethod,
    RideNotes notes = RideNotes.empty,
    required BookingAttempt attempt,
  }) async {
    final key = attempt.idempotencyKey;
    final json = await _client.post(
      '/api/v1/rides',
      body: {
        'pickupAddress': pickupAddress,
        'destinationAddress': destinationAddress,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        'rideType': rideType,
        'price': price,
        'paymentMethod': paymentMethod,
        // Bags, pet, baby and child are accessibility and safety options, not
        // cosmetics: the driver needs them before accepting, so they travel
        // with the booking rather than stopping at the selection screen.
        'notes': notes.toJson(),
      },
      idempotencyKey: key,
    );
    final id = (json['ride'] is Map ? json['ride']['id'] : key).toString();
    Analytics.bookingSubmitted(rideId: id);
    AppScope.instance.ride.restoreFromBackend(RideStatus.findingDriver, id: id);
    await RideSnapshotStore.save(
      RideSnapshot(
        status: RideStatus.findingDriver,
        savedAt: DateTime.now(),
        pickupAddress: pickupAddress,
        destinationAddress: destinationAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        rideType: rideType,
        price: price,
        paymentMethod: paymentMethod,
        rideId: id,
        notes: notes,
      ),
    );
    return id;
  }

  Future<void> cancel({required String rideId, required String key}) {
    return _client.post('/api/v1/rides/$rideId/cancel', idempotencyKey: key);
  }
}
