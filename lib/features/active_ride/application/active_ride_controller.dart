import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class ActiveRideController {
  void markArriving() {
    AppScope.instance.ride.restoreFromBackend(RideStatus.driverArriving);
  }

  void markCancelled() {
    AppScope.instance.ride.restoreFromBackend(RideStatus.cancelledByRider);
    RideSnapshotStore.clear();
  }

  void markCompleted() {
    AppScope.instance.ride.restoreFromBackend(RideStatus.tripCompleted);
    RideSnapshotStore.clear();
  }
}
