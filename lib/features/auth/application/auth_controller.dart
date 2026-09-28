import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/location/location_repository.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/features/auth/data/auth_repository.dart';
import 'package:movera_rider/features/auth/domain/otp_challenge.dart';

class AuthController {
  AuthController({AuthRepository? auth}) : _auth = auth ?? AuthRepository();

  final AuthRepository _auth;
  OtpChallenge? lastChallenge;

  String? get lastPhone => lastChallenge?.phone;

  Future<OtpChallenge> requestOtp({
    required String phone,
    ProviderLink? link,
  }) async {
    final challenge = await _auth.requestOtp(phone: phone, link: link);
    lastChallenge = challenge;
    return challenge;
  }

  Future<OtpVerifyResult> verifyOtp({
    required OtpChallenge challenge,
    required String code,
  }) async {
    final result = await _auth.verifyOtp(challenge: challenge, code: code);
    lastChallenge = null;
    await _registerPushBestEffort();
    return result;
  }

  /// Apple or Google. Push registers only once a session exists, which for
  /// a first-time provider rider is after the phone code.
  Future<ProviderSignInResult> signIn({required String provider}) async {
    final result = await _auth.signIn(provider: provider);
    if (result is ProviderSignedIn) await _registerPushBestEffort();
    return result;
  }

  Future<bool> hasSession() => _auth.hasSession();

  Future<void> _registerPushBestEffort() async {
    try {
      await AppScope.instance.push.register();
    } catch (error) {
      AppLog.warning(
        'auth.push_registration_deferred',
        extra: {'error': error.toString()},
      );
    }
  }

  Future<void> signOut() async {
    // Unregister while the access token is still available. Even when the
    // backend is unreachable, FirebasePushService deletes the local token so a
    // signed-out Rider cannot keep receiving notifications for that session.
    try {
      await AppScope.instance.push.unregister();
    } catch (error) {
      AppLog.warning(
        'auth.push_unregister_deferred',
        extra: {'error': error.toString()},
      );
    }
    try {
      await _auth.signOut();
    } finally {
      // Local wipe even when the backend sign-out fails (tokens are cleared
      // the same way in AuthRepository.signOut).
      await LocationRepository.clearLastGoodFix();
    }
  }
}
