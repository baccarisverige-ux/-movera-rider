import 'package:flutter/foundation.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_policy.dart';
import 'package:movera_rider/features/reservations/domain/reservation_repository.dart';

class ReservationController extends ChangeNotifier {
  ReservationController({ReservationRepository? store})
    : _store = store ?? LocalReservationRepository();

  final ReservationRepository _store;

  List<Reservation> get all => _store.cached;

  ReservationPolicy get policy => _store.policy;

  List<Reservation> upcoming() =>
      _store.cached.where((item) => item.status.isUpcoming).toList();

  List<Reservation> completed() =>
      _store.cached.where((item) => item.status.isCompleted).toList();

  List<Reservation> cancelled() =>
      _store.cached.where((item) => item.status.isCancelled).toList();

  Reservation? byId(String reservationId) {
    for (final item in _store.cached) {
      if (item.reservationId == reservationId) return item;
    }
    return null;
  }

  Future<void> hydrate() async {
    await _store.hydrate();
    notifyListeners();
  }

  Future<Reservation> create(ReservationDraft draft) async {
    final created = await _store.createReservation(draft);
    notifyListeners();
    return created;
  }

  Future<Reservation> update(
    String reservationId,
    ReservationPatch patch,
  ) async {
    final updated = await _store.updateReservation(reservationId, patch);
    notifyListeners();
    return updated;
  }

  Future<Reservation> cancel(String reservationId, {String? reason}) async {
    final updated = await _store.cancelReservation(
      reservationId,
      reason: reason,
    );
    notifyListeners();
    return updated;
  }

  Future<Reservation> assignMockDriver(
    String reservationId, {
    ReservationDriver? driver,
  }) async {
    final updated = await _store.assignDriver(reservationId, driver: driver);
    notifyListeners();
    return updated;
  }

  Future<Reservation> planReturn(
    Reservation origin, {
    required DateTime scheduledPickupAt,
    DateTime? estimatedDropoffAt,
    ReservationPlace? pickup,
    ReservationPlace? destination,
    String? paymentMethod,
    double? price,
  }) {
    return create(
      ReservationDraft(
        scheduledPickupAt: scheduledPickupAt,
        estimatedDropoffAt: estimatedDropoffAt,
        pickup: pickup ?? origin.destination,
        destination: destination ?? origin.pickup,
        categoryId: origin.categoryId,
        categoryName: origin.categoryName,
        categoryImage: origin.categoryImage,
        passengerCount: origin.passengerCount,
        price: price ?? origin.price,
        currency: origin.currency,
        paymentMethod: paymentMethod ?? origin.paymentMethod,
        note: origin.note,
        parentReservationId: origin.reservationId,
      ),
    );
  }
}
