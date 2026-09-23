import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/auth/token_store.dart';

class AuthRepository {
  AuthRepository({ApiClient? api, TokenStore? tokens})
      : _api = api ?? AppScope.instance.api,
        _tokens = tokens ?? AppScope.instance.tokens;

  final ApiClient _api;
  final TokenStore _tokens;

  Future<void> requestOtp({required String phone}) async {
    final normalized = phone.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(phone, 'phone', 'Phone number is required.');
    }
    await _api.post('/api/v1/auth/otp/request', body: {'phone': normalized});
  }

  Future<void> signIn({required String provider}) async {
    final response = await _api.post('/api/v1/auth/provider', body: {'provider': provider});
    final access = response['accessToken'];
    final refresh = response['refreshToken'];
    if (access is! String || access.isEmpty || refresh is! String || refresh.isEmpty) {
      throw StateError('Authentication response did not contain valid tokens.');
    }
    await _tokens.save(access: access, refresh: refresh);
  }

  Future<void> signOut() async {
    try {
      await _api.post('/api/v1/auth/sign-out');
    } finally {
      await _tokens.clear();
    }
  }
}
