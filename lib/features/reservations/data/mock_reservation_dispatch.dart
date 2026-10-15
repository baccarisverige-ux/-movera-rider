import 'dart:async';

import 'package:movera_rider/core/contracts/matched_driver.dart';
import 'package:movera_rider/core/realtime/mock_driver_pool.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_dispatch.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';

/// Simulated scheduled-ride dispatch for demo/dev/test builds only.
///
/// Like `MockRideRealtime` for Book Now, this stands in for the backend: it
/// hands back a driver from the same [MockDriverPool] and then plays the trip
/// forward (en route → arrived → in progress → completed) on accelerated,
/// seconds-long timers so a demo reaches the receipt quickly. It is composed
/// in `di.dart` only when `AppEnv.allowsMockTransport` is true; staging and
/// production never construct it.
///
/// Demo script for a ride booked well ahead: a driver accepts it shortly
/// after booking ([acceptAfterBooking]), and once, [driverChangeAfter] later,
/// hands it over to another driver, so the rider sees the driver change.
class MockReservationDispatch implements ReservationDispatch {
  MockReservationDispatch({
    this.assignmentLead = const Duration(minutes: 30),
    this.acceptAfterBooking = const Duration(seconds: 15),
    this.driverChangeAfter = const Duration(seconds: 30),
    this.arriveAfter = const Duration(seconds: 20),
    this.boardAfter = const Duration(seconds: 8),
    this.tripDuration = const Duration(seconds: 18),
  });

  @override
  final Duration assignmentLead;

  @override
  final Duration? acceptAfterBooking;

  /// How long the first driver keeps an accepted ride before handing it to
  /// another driver. Null: the driver never changes on its own.
  final Duration? driverChangeAfter;

  /// En route → arrived at pickup.
  final Duration arriveAfter;

  /// Arrived → rider on board (trip in progress). Same as Book Now's mock.
  final Duration boardAfter;

  /// In progress → completed. Book Now's mock uses 6 × 3 s.
  final Duration tripDuration;

  final Map<String, int> _attempts = {};
  final Map<String, Timer> _steps = {};

  /// When this dispatch first saw each accepted ride (the handover clock).
  final Map<String, DateTime> _acceptedSeenAt = {};
  final Set<String> _handedOver = {};
  bool _disposed = false;

  @override
  ReservationDriver? driverFor(Reservation ride) {
    if (_disposed) return null;
    final id = ride.reservationId;
    // Attempt 0 is stable per reservation (same driver across restarts);
    // a later re-offer after a driver drop picks someone else.
    final attempt = _attempts[id] ?? 0;
    _attempts[id] = attempt + 1;
    return _driverOf(MockDriverPool.forRide(id, attempt: attempt));
  }

  @override
  ReservationDriver? handoverFor(Reservation ride, DateTime now) {
    final after = driverChangeAfter;
    final current = ride.driver;
    final id = ride.reservationId;
    // Once per ride: a ride whose driver already changed keeps the new one.
    if (_disposed ||
        after == null ||
        current == null ||
        ride.previousDriver != null ||
        _handedOver.contains(id)) {
      return null;
    }
    final seenAt = _acceptedSeenAt.putIfAbsent(id, () => now);
    if (now.difference(seenAt) < after) return null;
    _handedOver.add(id);
    // The pool is small and restarts reset the attempt count, so skip the
    // driver who is handing the ride over.
    for (var tries = 0; tries < 4; tries++) {
      final next = driverFor(ride);
      if (next == null) return null;
      if (!next.isSameAs(current)) return next;
    }
    return null;
  }

  static ReservationDriver _driverOf(MatchedDriver matched) {
    final vehicle = [
      matched.vehicleMake,
      matched.vehicleModel,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    return ReservationDriver(
      firstName: matched.firstName,
      id: matched.id,
      rating: matched.rating,
      vehicle: vehicle.isEmpty ? null : vehicle,
      vehicleColor: matched.vehicleColor,
      plate: matched.plate,
      photoAsset: matched.photoAsset,
    );
  }

  @override
  void driveTrip(
    String reservationId,
    ReservationStatus current,
    ReservationStepWriter writeStep,
  ) {
    if (_disposed || _steps.containsKey(reservationId)) return;
    final (Duration after, ReservationStatus next)? step = switch (current) {
      ReservationStatus.driverEnRoute => (
        arriveAfter,
        ReservationStatus.driverArrived,
      ),
      ReservationStatus.driverArrived => (
        boardAfter,
        ReservationStatus.inProgress,
      ),
      ReservationStatus.inProgress => (
        tripDuration,
        ReservationStatus.completed,
      ),
      _ => null,
    };
    if (step == null) return;
    _steps[reservationId] = Timer(step.$1, () async {
      _steps.remove(reservationId);
      if (_disposed) return;
      final written = await writeStep(current, step.$2);
      if (written) driveTrip(reservationId, step.$2, writeStep);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _steps.values) {
      timer.cancel();
    }
    _steps.clear();
  }
}
