abstract class PromotionsRepository {
  Future<void> refresh();
}

class LocalPromotionsRepository implements PromotionsRepository {
  @override
  Future<void> refresh() async {}
}
