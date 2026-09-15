import 'package:movera_rider/features/history/data/on_demand_ride_history_store.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';

/// Read-only application layer for Book Now ride history.
///
/// It intentionally owns no demo data. The local archive is the temporary
/// source of truth until the production backend replaces it behind this API.
class OnDemandHistoryController {
  const OnDemandHistoryController();

  Future<List<Reservation>> load() => OnDemandRideHistoryStore.read();

  List<Reservation> combine(
    List<Reservation> reservations,
    List<Reservation> onDemand, {
    required bool completed,
  }) {
    final byId = <String, Reservation>{};
    for (final ride in [...reservations, ...onDemand]) {
      final belongs = completed
          ? ride.status.isCompleted
          : ride.status.isCancelled;
      if (!belongs) continue;
      final current = byId[ride.reservationId];
      if (current == null ||
          ride.scheduledPickupAt.isAfter(current.scheduledPickupAt)) {
        byId[ride.reservationId] = ride;
      }
    }
    final rides = byId.values.toList()
      ..sort((a, b) => b.scheduledPickupAt.compareTo(a.scheduledPickupAt));
    return rides;
  }
}
