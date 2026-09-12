abstract class DriverArrivingRepository {
  Future<void> refresh();
}

class LocalDriverArrivingRepository implements DriverArrivingRepository {
  @override
  Future<void> refresh() async {}
}
