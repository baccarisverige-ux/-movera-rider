import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/features/reservations/domain/scheduled_ride_rules.dart';

/// Reads the admin-set scheduled-ride rules from
/// `GET /api/v1/rider/scheduled-rides/rules` (PROPOSED). The in-process mock
/// answers in demo builds; release builds have Book for later switched off
/// and do not compose this.
class ApiScheduledRideRulesSource implements ScheduledRideRulesSource {
  ApiScheduledRideRulesSource(this._api);

  static const path = '/api/v1/rider/scheduled-rides/rules';

  final ApiClient _api;

  @override
  Future<ScheduledRideRules?> fetch() async {
    try {
      final body = await _api.get(path);
      final rules = body['rules'];
      if (rules is! Map) return null;
      return ScheduledRideRules.fromJson(rules);
    } catch (error) {
      // The rider keeps the rules already held (defaults at worst).
      AppLog.warning(
        'reservation.rules.fetch_failed',
        extra: {'error': error.runtimeType.toString()},
      );
      return null;
    }
  }
}
