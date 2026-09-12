import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/active_ride/data/active_ride_repository.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class ActiveRideController {
  ActiveRideController({ActiveRideRepository? store})
      : _store = store ?? ActiveRideRepository();
  final ActiveRideRepository _store;

  void markArriving() {
    AppScope.instance.ride.restoreFromBackend(RideStatus.driverArriving);
  }

  void markCancelled() {
    AppScope.instance.ride.restoreFromBackend(RideStatus.cancelledByRider);
    _store.clear();
  }

  void markClosed() {
    AppScope.instance.ride.restoreFromBackend(RideStatus.closed);
    _store.clear();
  }
}
