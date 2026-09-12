abstract class FindingDriverRepository {
  Future<void> refresh();
}

class LocalFindingDriverRepository implements FindingDriverRepository {
  @override
  Future<void> refresh() async {}
}
