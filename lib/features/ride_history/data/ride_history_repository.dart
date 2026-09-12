abstract class RideHistoryRepository {
  Future<void> refresh();
}

class LocalRideHistoryRepository implements RideHistoryRepository {
  @override
  Future<void> refresh() async {}
}
