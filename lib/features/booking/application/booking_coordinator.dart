import 'dart:convert';
import 'dart:math' as math;

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/features/booking/application/booking_attempt.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/ride_booking/data/api_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class BookingCoordinator {
  BookingCoordinator({ApiClient? api}) : _api = api;

  final ApiClient? _api;
  Future<String>? _inflight;
  BookingAttempt? _attempt;
  String? _autoQuoteIntent;
  _BookingQuoteBinding? _autoQuoteBinding;

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
    String? quoteId,
    String? quoteSignedPayload,
    DateTime? quoteExpiresAt,
    int? quoteTotalMinor,
    String? rideTypeLabel,
    String? paymentMethodLabel,
    RideNotes notes = RideNotes.empty,
  }) {
    if (_inflight != null) return _inflight!;
    if (_findingAlreadyActive) {
      return _refuseOrExisting();
    }

    final started = _prepareFinding(
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      rideType: rideType,
      requestedPrice: price,
      paymentMethod: paymentMethod,
      quoteId: quoteId,
      quoteSignedPayload: quoteSignedPayload,
      quoteExpiresAt: quoteExpiresAt,
      quoteTotalMinor: quoteTotalMinor,
      rideTypeLabel: rideTypeLabel,
      paymentMethodLabel: paymentMethodLabel,
      notes: notes,
    );
    _inflight = started;
    started.then<void>(
      (_) {
        if (identical(_inflight, started)) _inflight = null;
      },
      onError: (Object _, StackTrace __) {
        if (identical(_inflight, started)) _inflight = null;
      },
    );
    return started;
  }

  Future<String> _prepareFinding({
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    required String rideType,
    required double requestedPrice,
    required String paymentMethod,
    String? quoteId,
    String? quoteSignedPayload,
    DateTime? quoteExpiresAt,
    int? quoteTotalMinor,
    String? rideTypeLabel,
    String? paymentMethodLabel,
    RideNotes notes = RideNotes.empty,
  }) async {
    final baseIntent = jsonEncode(<String, Object?>{
      'pickupAddress': pickupAddress,
      'destinationAddress': destinationAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'categoryId': rideType,
      'paymentMethodId': paymentMethod,
      'notes': notes.toJson(),
    });

    final binding = await _resolveQuoteBinding(
      baseIntent: baseIntent,
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      rideType: rideType,
      requestedPrice: requestedPrice,
      quoteId: quoteId,
      quoteSignedPayload: quoteSignedPayload,
      quoteExpiresAt: quoteExpiresAt,
      quoteTotalMinor: quoteTotalMinor,
    );
    final effectivePrice = binding.totalMinor / 100;

    final intentKey = jsonEncode(<String, Object?>{
      'operation': 'submitFinding',
      'baseIntent': baseIntent,
      'price': effectivePrice,
      'quoteId': binding.id,
      'quoteSignedPayload': binding.signedPayload,
      'quoteExpiresAt': binding.expiresAt.toUtc().toIso8601String(),
      'quoteTotalMinor': binding.totalMinor,
    });
    final attempt = _attemptFor(intentKey);

    try {
      final id = await _submitFinding(
        pickupAddress: pickupAddress,
        destinationAddress: destinationAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        rideType: rideType,
        price: effectivePrice,
        paymentMethod: paymentMethod,
        quoteId: binding.id,
        quoteSignedPayload: binding.signedPayload,
        quoteExpiresAt: binding.expiresAt,
        quoteTotalMinor: binding.totalMinor,
        rideTypeLabel: rideTypeLabel,
        paymentMethodLabel: paymentMethodLabel,
        notes: notes,
        attempt: attempt,
      );
      if (identical(_attempt, attempt)) _attempt = null;
      if (_autoQuoteIntent == baseIntent) {
        _autoQuoteIntent = null;
        _autoQuoteBinding = null;
      }
      return id;
    } catch (_) {
      rethrow;
    }
  }

  Future<_BookingQuoteBinding> _resolveQuoteBinding({
    required String baseIntent,
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    required String rideType,
    required double requestedPrice,
    String? quoteId,
    String? quoteSignedPayload,
    DateTime? quoteExpiresAt,
    int? quoteTotalMinor,
  }) async {
    final supplied = <Object?>[
      quoteId,
      quoteSignedPayload,
      quoteExpiresAt,
      quoteTotalMinor,
    ];
    final suppliedCount = supplied.where((value) => value != null).length;
    if (suppliedCount != 0 && suppliedCount != supplied.length) {
      throw StateError('Incomplete authoritative quote binding');
    }

    if (suppliedCount == supplied.length) {
      final binding = _BookingQuoteBinding(
        id: quoteId!,
        signedPayload: quoteSignedPayload!,
        expiresAt: quoteExpiresAt!,
        totalMinor: quoteTotalMinor!,
      );
      binding.validate(requestedPrice: requestedPrice);
      return binding;
    }

    final cached = _autoQuoteBinding;
    if (_autoQuoteIntent == baseIntent &&
        cached != null &&
        cached.expiresAt.isAfter(DateTime.now())) {
      return cached;
    }

    final quote = await ApiQuoteRepository(api: _client).quote(
      rideType: rideType,
      distanceMeters: _approxDistanceMeters(
        pickupLat,
        pickupLng,
        destinationLat,
        destinationLng,
      ),
      pickup: pickupAddress,
      destination: destinationAddress,
    );
    final binding = _BookingQuoteBinding(
      id: quote.id,
      signedPayload: quote.signedPayload ?? '',
      expiresAt: quote.expiresAt,
      totalMinor: quote.totalMinor,
    )..validate();

    _autoQuoteIntent = baseIntent;
    _autoQuoteBinding = binding;
    return binding;
  }

  int _approxDistanceMeters(
    double pickupLat,
    double pickupLng,
    double destinationLat,
    double destinationLng,
  ) {
    const earthRadiusMeters = 6371000.0;
    final lat1 = pickupLat * math.pi / 180;
    final lat2 = destinationLat * math.pi / 180;
    final dLat = (destinationLat - pickupLat) * math.pi / 180;
    final dLng = (destinationLng - pickupLng) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return math.max(1, (earthRadiusMeters * c).round());
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

    final collisionBeforeCommit = await _standDownIfFindingOwned(
      createdRideId: id,
      attempt: attempt,
    );
    if (collisionBeforeCommit != null) return collisionBeforeCommit;

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

    // The snapshot save crosses an async boundary. A Finding surface can
    // become authoritative while persistence is in flight, so close that
    // second race window before returning the created id to presentation.
    final collisionAfterCommit = await _standDownIfFindingOwned(
      createdRideId: id,
      attempt: attempt,
    );
    if (collisionAfterCommit != null) return collisionAfterCommit;

    return id;
  }

  Future<String?> _standDownIfFindingOwned({
    required String createdRideId,
    required BookingAttempt attempt,
  }) async {
    final owner = FindingDriverController.active;
    if (owner == null) return null;

    final ownerId = owner.ownedRideId;
    final ownerSnapshot = owner.ownershipSnapshot;
    if (ownerId == null ||
        ownerId.isEmpty ||
        ownerSnapshot == null ||
        ownerId == createdRideId) {
      return ownerId == createdRideId ? createdRideId : null;
    }

    // A visible Finding surface already owns another ride. The race-losing
    // backend ride must be explicitly stood down; never leave two live rides.
    await _client.post(
      '/api/v1/rides/$createdRideId/cancel',
      idempotencyKey: '${attempt.idempotencyKey}:duplicate-cancel',
    );

    // Restore the visible owner's identity after the duplicate create response
    // may have temporarily projected the new id into the process-wide session.
    AppScope.instance.ride.backendReconcile(
      ownerSnapshot.status,
      id: ownerId,
    );
    await RideSnapshotStore.save(
      ownerSnapshot.copyWith(savedAt: DateTime.now()),
    );
    return ownerId;
  }

  Future<void> cancel({required String rideId, required String key}) {
    return _client.post('/api/v1/rides/$rideId/cancel', idempotencyKey: key);
  }
}


class _BookingQuoteBinding {
  const _BookingQuoteBinding({
    required this.id,
    required this.signedPayload,
    required this.expiresAt,
    required this.totalMinor,
  });

  final String id;
  final String signedPayload;
  final DateTime expiresAt;
  final int totalMinor;

  void validate({double? requestedPrice}) {
    if (id.trim().isEmpty ||
        signedPayload.trim().isEmpty ||
        !expiresAt.isAfter(DateTime.now()) ||
        totalMinor <= 0) {
      throw StateError('A fresh authoritative quote is required for booking');
    }
    if (requestedPrice != null &&
        (requestedPrice * 100).round() != totalMinor) {
      throw StateError('Selected fare no longer matches the authoritative quote');
    }
  }
}
