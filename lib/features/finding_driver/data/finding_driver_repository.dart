import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';

class FindingDriverRepository {
  Future<void> save(RideSnapshot snapshot) => RideSnapshotStore.save(snapshot);
  void clear() => RideSnapshotStore.clear();
}
