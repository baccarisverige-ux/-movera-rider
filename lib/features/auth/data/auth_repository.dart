import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/auth/token_store.dart';
import 'package:movera_rider/features/auth/domain/otp_challenge.dart';

class AuthRepository {
  AuthRepository({ApiClient? api, TokenStore? tokens})
      : _api = api ?? AppScope.instance.api,
        _tokens = tokens ?? AppScope.instance.tokens;

  final ApiClient _api;
  final TokenStore _tokens;

  Future<OtpChallenge> requestOtp({required String phone}) async {
    final normalized = phone.replaceAll(' ', '').trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(phone, 'phone', 'Phone number is required.');
    }
    final response = await _api.post(
      '/api/v1/auth/otp/request',
      body: {'phone': normalized},
    );
    final requestId = response['requestId'];
    final sessionId = response['sessionId'];
    final expiresAt = DateTime.tryParse('${response['expiresAt'] ?? ''}');
    final retryAfterSeconds = (response['retryAfterSeconds'] as num?)?.toInt();
    if (requestId is! String ||
        requestId.isEmpty ||
        sessionId is! String ||
        sessionId.isEmpty ||
        expiresAt == null ||
        retryAfterSeconds == null ||
        retryAfterSeconds < 0) {
      throw StateError('OTP request response was incomplete.');
    }
    return OtpChallenge(
      phone: normalized,
      requestId: requestId,
      sessionId: sessionId,
      expiresAt: expiresAt.toUtc(),
      retryAfter: Duration(seconds: retryAfterSeconds),
    );
  }

  Future<void> verifyOtp({
    required OtpChallenge challenge,
    required String code,
  }) async {
    final normalizedCode = code.trim();
    if (challenge.isExpired) {
      throw StateError('OTP challenge has expired.');
    }
    if (!RegExp(r'^\d{4}$').hasMatch(normalizedCode)) {
      throw ArgumentError.value(code, 'code', 'A 4-digit code is required.');
    }
    final response = await _api.post(
      '/api/v1/auth/otp/verify',
      body: {
        'phone': challenge.phone,
        'sessionId': challenge.sessionId,
        'code': normalizedCode,
      },
    );
    await _persistTokens(response);
  }

  Future<void> signIn({required String provider}) async {
    final normalized = provider.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(provider, 'provider', 'Provider is required.');
    }
    final response = await _api.post(
      '/api/v1/auth/provider',
      body: {'provider': normalized},
    );
    await _persistTokens(response);
  }

  Future<void> _persistTokens(Map<String, dynamic> response) async {
    final access = response['accessToken'];
    final refresh = response['refreshToken'];
    if (access is! String ||
        access.isEmpty ||
        refresh is! String ||
        refresh.isEmpty) {
      throw StateError('Authentication response did not contain valid tokens.');
    }
    await _tokens.save(access: access, refresh: refresh);
  }

  Future<bool> hasSession() async {
    final access = await _tokens.readAccess();
    final refresh = await _tokens.readRefresh();
    return access?.isNotEmpty == true && refresh?.isNotEmpty == true;
  }

  Future<void> signOut() async {
    try {
      await _api.post('/api/v1/auth/sign-out');
    } finally {
      await _tokens.clear();
    }
  }
}
