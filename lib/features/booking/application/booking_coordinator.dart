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

  String _requireRideId(Map<String, dynamic> json) {
    final rawRide = json['ride'];
    if (rawRide is! Map) {
      throw const FormatException('Booking response missing ride object');
    }
    final rawId = rawRide['id'];
    if (rawId is! String) {
      throw const FormatException('Booking response missing ride id');
    }
    final id = rawId.trim();
    if (id.isEmpty || id.toLowerCase() == 'null') {
      throw const FormatException('Booking response contains invalid ride id');
    }
    return id;
  }

  int? _rideVersion(Map<String, dynamic> json) {
    final ride = json['ride'];
    if (ride is! Map) return null;
    return (ride['version'] as num?)?.toInt();
  }

  DateTime? _rideUpdatedAt(Map<String, dynamic> json) {
    final ride = json['ride'];
    if (ride is! Map) return null;
    return DateTime.tryParse(ride['updatedAt'] as String? ?? '');
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
        'categoryId': rideType,
        'paymentMethodId': paymentMethod,
        'scheduledAt': scheduledAt,
      },
      idempotencyKey: id,
    );
    final rideId = _requireRideId(json);
    AppScope.instance.ride.backendReconcile(
      RideStatus.bookingRequested,
      id: rideId,
      version: _rideVersion(json),
      updatedAt: _rideUpdatedAt(json),
    );
    Analytics.bookingSubmitted(rideId: rideId);
    if (scheduledAt == null) {
      AppScope.instance.ride.backendReconcile(
        RideStatus.findingDriver,
        id: rideId,
        version: _rideVersion(json),
        updatedAt: _rideUpdatedAt(json),
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
    required String quoteId,
    required String quoteSignedPayload,
    required DateTime quoteExpiresAt,
    required int quoteTotalMinor,
    String? rideTypeLabel,
    String? paymentMethodLabel,
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
      'categoryId': rideType,
      'price': price,
      'paymentMethodId': paymentMethod,
      'quoteId': quoteId,
      'quoteSignedPayload': quoteSignedPayload,
      'quoteExpiresAt': quoteExpiresAt.toUtc().toIso8601String(),
      'quoteTotalMinor': quoteTotalMinor,
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
      quoteId: quoteId,
      quoteSignedPayload: quoteSignedPayload,
      quoteExpiresAt: quoteExpiresAt,
      quoteTotalMinor: quoteTotalMinor,
      rideTypeLabel: rideTypeLabel,
      paymentMethodLabel: paymentMethodLabel,
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
    required String quoteId,
    required String quoteSignedPayload,
    required DateTime quoteExpiresAt,
    required int quoteTotalMinor,
    String? rideTypeLabel,
    String? paymentMethodLabel,
    RideNotes notes = RideNotes.empty,
    required BookingAttempt attempt,
  }) async {
    if (quoteId.trim().isEmpty ||
        quoteSignedPayload.trim().isEmpty ||
        !quoteExpiresAt.isAfter(DateTime.now()) ||
        quoteTotalMinor <= 0 ||
        (price * 100).round() != quoteTotalMinor) {
      throw StateError('A fresh authoritative quote is required for booking');
    }

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
        'categoryId': rideType,
        'price': price,
        'paymentMethodId': paymentMethod,
        'quoteId': quoteId,
        'quoteSignedPayload': quoteSignedPayload,
        'quoteExpiresAt': quoteExpiresAt.toUtc().toIso8601String(),
        'quoteTotalMinor': quoteTotalMinor,
        // Bags, pet, baby and child are accessibility and safety options, not
        // cosmetics: the driver needs them before accepting, so they travel
        // with the booking rather than stopping at the selection screen.
        'notes': notes.toJson(),
      },
      idempotencyKey: key,
    );
    final id = _requireRideId(json);
    Analytics.bookingSubmitted(rideId: id);
    AppScope.instance.ride.backendReconcile(
      RideStatus.findingDriver,
      id: id,
      version: _rideVersion(json),
      updatedAt: _rideUpdatedAt(json),
    );
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
        rideType: rideTypeLabel ?? rideType,
        price: price,
        paymentMethod: paymentMethodLabel ?? paymentMethod,
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
