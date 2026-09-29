import 'dart:async';

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
class MockReservationDispatch implements ReservationDispatch {
  MockReservationDispatch({
    this.assignmentLead = const Duration(minutes: 30),
    this.arriveAfter = const Duration(seconds: 20),
    this.boardAfter = const Duration(seconds: 8),
    this.tripDuration = const Duration(seconds: 18),
  });

  @override
  final Duration assignmentLead;

  /// En route → arrived at pickup.
  final Duration arriveAfter;

  /// Arrived → rider on board (trip in progress). Same as Book Now's mock.
  final Duration boardAfter;

  /// In progress → completed. Book Now's mock uses 6 × 3 s.
  final Duration tripDuration;

  final Map<String, int> _attempts = {};
  final Map<String, Timer> _steps = {};
  bool _disposed = false;

  @override
  ReservationDriver? driverFor(Reservation ride) {
    if (_disposed) return null;
    final id = ride.reservationId;
    // Attempt 0 is stable per reservation (same driver across restarts);
    // a later re-offer after a driver drop picks someone else.
    final attempt = _attempts[id] ?? 0;
    _attempts[id] = attempt + 1;
    final matched = MockDriverPool.forRide(id, attempt: attempt);
    final vehicle = [
      matched.vehicleMake,
      matched.vehicleModel,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
    return ReservationDriver(
      firstName: matched.firstName,
      rating: matched.rating,
      vehicle: vehicle.isEmpty ? null : vehicle,
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
