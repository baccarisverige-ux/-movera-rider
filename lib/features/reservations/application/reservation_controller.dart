import 'package:flutter/foundation.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_policy.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';
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

  Future<void> startLiveIfDue({DateTime? now}) async {
    final clock = now ?? DateTime.now();
    var changed = false;
    for (final ride in upcoming()) {
      if (ride.revealsDriver) continue;
      if (ride.scheduledPickupAt.difference(clock).inMinutes > 2) continue;
      if (ride.driver == null) {
        if (ride.status != ReservationStatus.driverAssignmentPending) {
          await _store.assignDriver(ride.reservationId);
          changed = true;
        }
        continue;
      }
      await _store.updateReservation(
        ride.reservationId,
        const ReservationPatch(status: ReservationStatus.driverEnRoute),
      );
      changed = true;
    }
    if (changed) notifyListeners();
  }

  Future<Reservation> planReturn(
    Reservation origin, {
    required DateTime scheduledPickupAt,
    DateTime? estimatedDropoffAt,
    ReservationPlace? pickup,
    ReservationPlace? destination,
    String? paymentMethod,
    double? price,
    String? categoryId,
    String? categoryName,
    String? categoryImage,
    int? passengerCount,
    String? note,
  }) {
    return create(
      ReservationDraft(
        scheduledPickupAt: scheduledPickupAt,
        estimatedDropoffAt: estimatedDropoffAt,
        pickup: pickup ?? origin.destination,
        destination: destination ?? origin.pickup,
        categoryId: categoryId ?? origin.categoryId,
        categoryName: categoryName ?? origin.categoryName,
        categoryImage: categoryImage ?? origin.categoryImage,
        passengerCount: passengerCount ?? origin.passengerCount,
        price: price ?? origin.price,
        currency: origin.currency,
        paymentMethod: paymentMethod ?? origin.paymentMethod,
        note: note ?? origin.note,
        parentReservationId: origin.reservationId,
      ),
    );
  }
}
