import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/features/profile/domain/account_security.dart';

class AccountSecurityRepository {
  AccountSecurityRepository({required ApiClient api}) : _api = api;

  final ApiClient _api;

  Future<AccountSecurityState> load() async {
    final response = await _api.get('/api/v1/account/security');
    return _decode(response);
  }

  Future<AccountSecurityState> signOutOtherDevices() async {
    await _api.post('/api/v1/account/security/sessions/sign-out-others');
    return load();
  }

  AccountSecurityState _decode(Map<String, dynamic> response) {
    final raw = response['security'];
    if (raw is! Map) {
      throw StateError('Account security response was incomplete.');
    }
    return AccountSecurityState.fromJson(Map<String, dynamic>.from(raw));
  }
}
