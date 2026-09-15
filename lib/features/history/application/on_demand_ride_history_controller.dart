import 'package:movera_rider/features/history/data/on_demand_ride_history_store.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';

class OnDemandRideHistoryController {
  const OnDemandRideHistoryController();

  Future<List<Reservation>> load() => OnDemandRideHistoryStore.read();
}
