abstract class SupportRepository {
  Future<void> refresh();
}

class LocalSupportRepository implements SupportRepository {
  @override
  Future<void> refresh() async {}
}
