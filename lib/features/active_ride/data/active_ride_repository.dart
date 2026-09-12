import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';

class ActiveRideRepository {
  Future<RideSnapshot?> restore() => RideSnapshotStore.read();
  void clear() => RideSnapshotStore.clear();
}
