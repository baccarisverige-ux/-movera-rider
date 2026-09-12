abstract class ActiveRideRepository {
  Future<void> refresh();
}

class LocalActiveRideRepository implements ActiveRideRepository {
  @override
  Future<void> refresh() async {}
}
