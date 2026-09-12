abstract class RideCompleteRepository {
  Future<void> refresh();
}

class LocalRideCompleteRepository implements RideCompleteRepository {
  @override
  Future<void> refresh() async {}
}
