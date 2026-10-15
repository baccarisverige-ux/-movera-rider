import 'package:movera_rider/core/contracts/money.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_policy.dart';

/// Backend-ready reservation store. Screens talk to the controller, which
/// talks to this interface. Swap the local implementation later.
abstract class ReservationRepository {
  List<Reservation> get cached;

  ReservationPolicy get policy;

  Future<void> hydrate();

  /// Forgets the cached reservations in memory (end of a rider's session).
  /// The next [hydrate] reads storage again.
  void clearLocal();

  Future<Reservation> createReservation(ReservationDraft draft);

  Future<Reservation> updateReservation(
    String reservationId,
    ReservationPatch patch,
  );

  /// Cancels the ride for the rider. [fee] is the late-cancel fee the rider
  /// was shown and agreed to; null when the cancel was free.
  Future<Reservation> cancelReservation(
    String reservationId, {
    String? reason,
    Money? fee,
  });

  Future<Reservation?> getReservation(String reservationId);

  Future<List<Reservation>> getUpcomingReservations();

  Future<List<Reservation>> getRideHistory();

  /// Gives the ride to [driver], or with null sends it back to waiting for
  /// one. A driver who loses the ride is kept as `previousDriver`, so the
  /// rider is told when the driver changes.
  Future<Reservation> assignDriver(
    String reservationId, {
    ReservationDriver? driver,
  });
}
