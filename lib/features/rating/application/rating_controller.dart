import 'package:movera_rider/features/rating/data/rating_repository.dart';

class RatingController {
  RatingController({RatingRepository? store}) : _store = store ?? RatingRepository();
  final RatingRepository _store;

  void set(double value) => _store.set(value);
  double get last => _store.last;
}
