abstract class FareRepository {
  Future<void> refresh();
}

class LocalFareRepository implements FareRepository {
  @override
  Future<void> refresh() async {}
}
