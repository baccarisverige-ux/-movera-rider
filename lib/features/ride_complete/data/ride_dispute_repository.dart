import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/mutation_attempt.dart';

/// Backend seam for disputing a completed ride/receipt.
/// The Rider never invents a dispute result locally.
class RideDisputeRepository {
  RideDisputeRepository({ApiClient? api}) : _api = api ?? AppScope.instance.api;

  final ApiClient _api;
  final MutationAttempt _mutation = MutationAttempt('ride-dispute');

  Future<void> submit({
    required String rideId,
    required String reason,
    String? detail,
  }) async {
    final normalizedReason = reason.trim();
    if (rideId.trim().isEmpty || normalizedReason.isEmpty) {
      throw ArgumentError('rideId and reason are required.');
    }
    final intent = '$rideId|$normalizedReason|${detail?.trim() ?? ''}';
    await _api.post(
      '/api/v1/rides/$rideId/disputes',
      body: {
        'reason': normalizedReason,
        if (detail != null && detail.trim().isNotEmpty) 'detail': detail.trim(),
      },
      idempotencyKey: _mutation.keyFor(intent),
    );
    _mutation.succeeded(intent);
  }
}
