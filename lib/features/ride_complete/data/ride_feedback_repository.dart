import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/api/api_client.dart';

/// Sends optional post-trip feedback through the same API transport as the ride.
/// An acknowledgement is required before the completion screen closes.
class RideFeedbackRepository {
  RideFeedbackRepository({ApiClient? api}) : _api = api ?? AppScope.instance.api;

  final ApiClient _api;

  Future<void> submit({
    required String rideId,
    double? rating,
    int? tipMinor,
    required String idempotencyKey,
  }) async {
    if (rideId.trim().isEmpty) throw ArgumentError.value(rideId, 'rideId');
    if (rating == null && tipMinor == null) return;
    if (rating != null && (rating < 1 || rating > 5 || rating * 2 != (rating * 2).round())) {
      throw ArgumentError.value(rating, 'rating');
    }
    if (tipMinor != null && (tipMinor <= 0 || tipMinor > 999900)) {
      throw ArgumentError.value(tipMinor, 'tipMinor');
    }
    final response = await _api.post(
      '/api/v1/rides/${Uri.encodeComponent(rideId)}/feedback',
      body: {
        if (rating != null) 'rating': rating,
        if (tipMinor != null) 'tipMinor': tipMinor,
        if (tipMinor != null) 'currency': 'SEK',
      },
      idempotencyKey: idempotencyKey,
    );
    if (response['code'] != 'OK' || response['status'] != 'accepted') {
      throw StateError('Ride feedback was not accepted.');
    }
  }
}
