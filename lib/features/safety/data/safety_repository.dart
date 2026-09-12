abstract class SafetyRepository {
  Future<void> refresh();
}

class LocalSafetyRepository implements SafetyRepository {
  @override
  Future<void> refresh() async {}
}
