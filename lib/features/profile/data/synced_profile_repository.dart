import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/core/contracts/repository_authority.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/features/profile/data/profile_repository.dart';
import 'package:movera_rider/features/profile/domain/profile.dart';
import 'package:movera_rider/features/profile/domain/rider_profile_repository.dart';

/// The profile the server knows (FLOW-7). The device copy stays as a cache
/// so screens read it synchronously; every save is also sent as
///
/// `PATCH /api/v1/rider/profile`
/// `{name, language, consents: {rideUpdates, emailUpdates, promotions}}`
///
/// PROPOSED, needs agreement with Driver, Admin and backend (contract C-12):
/// the driver app shows the rider's first name from it, and the consents are
/// the rider's marketing/notification choices. A save that does not reach
/// the server is kept on the device, marked [syncPending] and sent again
/// with the next save or launch.
class SyncedProfileRepository
    implements RiderProfileRepository, ServerBackedRepository {
  SyncedProfileRepository({required ApiClient api, ProfileRepository? cache})
    : _api = api,
      _cache = cache ?? ProfileRepository();

  static const path = '/api/v1/rider/profile';

  final ApiClient _api;
  final ProfileRepository _cache;
  bool _syncPending = false;

  /// True when the last saved profile has not reached the server yet.
  bool get syncPending => _syncPending;

  @override
  RiderProfileData get current => _cache.current;

  @override
  String displayName() => _cache.displayName();

  @override
  Future<void> hydrate() async {
    await _cache.hydrate();
    if (_syncPending) await _sync(_cache.current);
  }

  @override
  void clearLocal() {
    _cache.clearLocal();
    _syncPending = false;
  }

  @override
  Future<RiderProfileData> save(RiderProfileData next) async {
    final saved = await _cache.save(next);
    await _sync(saved);
    return saved;
  }

  static Map<String, dynamic> body(RiderProfileData profile) => {
    'name': profile.name.trim(),
    'language': profile.language,
    'consents': {
      'rideUpdates': profile.rideUpdates,
      'emailUpdates': profile.emailUpdates,
      'promotions': profile.promotions,
    },
  };

  Future<void> _sync(RiderProfileData profile) async {
    try {
      await _api.patch(
        path,
        body: body(profile),
        idempotencyKey: newIdempotencyKey('profile'),
      );
      _syncPending = false;
    } catch (error) {
      _syncPending = true;
      AppLog.warning('profile.sync_failed', extra: {'error': '$error'});
    }
  }
}
