import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/features/promotions/domain/rider_promotion.dart';

/// Reads the rider's active promotion from `/api/v1/rider/promotions/active`.
class RiderPromotionRepository {
  RiderPromotionRepository(this._api);

  final ApiClient _api;

  /// The active promotion, or null when the server has none (or is unreachable).
  Future<RiderPromotion?> fetchActive() async {
    try {
      final body = await _api.get('/api/v1/rider/promotions/active');
      return RiderPromotion.fromJson(body['promotion']);
    } catch (_) {
      return null;
    }
  }
}
