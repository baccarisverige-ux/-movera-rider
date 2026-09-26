import 'package:movera_rider/app/di.dart';
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
    String? fullName,
  }) async {
    final challenge = await _auth.requestOtp(
      phone: phone,
      fullName: fullName,
    );
    lastChallenge = challenge;
    return challenge;
  }

  Future<void> verifyOtp({
    required OtpChallenge challenge,
    required String code,
  }) async {
    await _auth.verifyOtp(challenge: challenge, code: code);
    lastChallenge = null;
    await _registerPushBestEffort();
  }

  Future<void> signIn({required String provider}) async {
    await _auth.signIn(provider: provider);
    await _registerPushBestEffort();
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
    await _auth.signOut();
  }
}
