abstract class HomeRepository {
  Future<void> refresh();
}

class LocalHomeRepository implements HomeRepository {
  @override
  Future<void> refresh() async {}
}
