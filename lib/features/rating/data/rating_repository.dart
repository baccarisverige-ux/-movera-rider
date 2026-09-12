abstract class RatingRepository {
  Future<void> refresh();
}

class LocalRatingRepository implements RatingRepository {
  @override
  Future<void> refresh() async {}
}
