import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_policy.dart';

/// Backend-ready reservation store. Screens talk to the controller, which
/// talks to this interface. Swap the local implementation later.
abstract class ReservationRepository {
  List<Reservation> get cached;

  ReservationPolicy get policy;

  Future<void> hydrate();

  Future<Reservation> createReservation(ReservationDraft draft);

  Future<Reservation> updateReservation(
    String reservationId,
    ReservationPatch patch,
  );

  Future<Reservation> cancelReservation(String reservationId, {String? reason});

  Future<Reservation?> getReservation(String reservationId);

  Future<List<Reservation>> getUpcomingReservations();

  Future<List<Reservation>> getRideHistory();

  Future<Reservation> assignDriver(
    String reservationId, {
    ReservationDriver? driver,
  });
}
