abstract class RideSelectionRepository {
  Future<void> refresh();
}

class LocalRideSelectionRepository implements RideSelectionRepository {
  @override
  Future<void> refresh() async {}
}
