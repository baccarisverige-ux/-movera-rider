abstract class PickupRepository {
  Future<void> refresh();
}

class LocalPickupRepository implements PickupRepository {
  @override
  Future<void> refresh() async {}
}
