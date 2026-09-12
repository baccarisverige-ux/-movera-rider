abstract class DestinationSearchRepository {
  Future<void> refresh();
}

class LocalDestinationSearchRepository implements DestinationSearchRepository {
  @override
  Future<void> refresh() async {}
}
