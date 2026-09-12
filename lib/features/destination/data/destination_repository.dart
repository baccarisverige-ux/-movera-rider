abstract class DestinationRepository {
  Future<void> refresh();
}

class LocalDestinationRepository implements DestinationRepository {
  @override
  Future<void> refresh() async {}
}
