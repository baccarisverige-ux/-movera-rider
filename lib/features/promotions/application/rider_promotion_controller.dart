import 'package:flutter/foundation.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/features/promotions/data/rider_promotion_repository.dart';
import 'package:movera_rider/features/promotions/domain/rider_promotion.dart';

export 'package:movera_rider/features/promotions/domain/rider_promotion.dart';

/// Holds the rider's active promotion for Home and the ride categories.
class RiderPromotionController extends ValueNotifier<RiderPromotion?> {
  RiderPromotionController(ApiClient api, {DateTime Function()? clock})
    : _repository = RiderPromotionRepository(api),
      _clock = clock ?? DateTime.now,
      super(null);

  final RiderPromotionRepository _repository;
  final DateTime Function() _clock;

  /// The promotion to show right now, or null.
  RiderPromotion? get active {
    final promotion = value;
    if (promotion == null || !promotion.isActiveAt(_clock())) return null;
    return promotion;
  }

  Future<void> refresh() async {
    value = await _repository.fetchActive();
  }
}
