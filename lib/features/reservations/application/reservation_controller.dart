import 'package:flutter/foundation.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_policy.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';
import 'package:movera_rider/features/reservations/domain/reservation_repository.dart';

class ReservationController extends ChangeNotifier {
  ReservationController({
    ReservationRepository? store,
    DateTime Function()? clock,
  }) : _store = store ?? LocalReservationRepository(),
       _clock = clock ?? DateTime.now;

  final ReservationRepository _store;
  final DateTime Function() _clock;

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

  /// The assigned driver drops a scheduled ride before pickup.
  ///
  /// Distinct from [cancel], which is the rider ending their own reservation.
  /// Here the reservation stands — its time, route and price are unchanged —
  /// and it returns to waiting for a driver rather than being cancelled.
  Future<Reservation> driverCancelled(String reservationId) async {
    final current = await _store.getReservation(reservationId);
    if (current == null) {
      throw StateError('No reservation $reservationId to reassign.');
    }
    if (!current.status.isUpcoming || !current.status.hasDriver) {
      // Nothing assigned to drop, or the ride is already over.
      return current;
    }
    final updated = await _store.assignDriver(reservationId, driver: null);
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
    final currentTime = now ?? _clock();
    var changed = false;
    for (final ride in upcoming()) {
      // The clock may begin assignment shortly before pickup, but it must
      // never fabricate a driver or advance a driver-assigned reservation
      // into a live state. Phase 62/realtime owns those transitions.
      if (ride.status != ReservationStatus.scheduled) continue;
      final untilPickup = ride.scheduledPickupAt.difference(currentTime);
      if (untilPickup > const Duration(minutes: 2)) continue;
      await _store.assignDriver(ride.reservationId);
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
