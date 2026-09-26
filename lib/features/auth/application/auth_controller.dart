import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/features/auth/data/auth_repository.dart';
import 'package:movera_rider/features/auth/domain/otp_challenge.dart';

class AuthController {
  AuthController({AuthRepository? auth}) : _auth = auth ?? AuthRepository();

  final AuthRepository _auth;
  OtpChallenge? lastChallenge;

  String? get lastPhone => lastChallenge?.phone;

  Future<OtpChallenge> requestOtp({required String phone}) async {
    final challenge = await _auth.requestOtp(phone: phone);
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
    await _auth.signOut();
    try {
      await AppScope.instance.push.unregister();
    } catch (error) {
      AppLog.warning(
        'auth.push_unregister_deferred',
        extra: {'error': error.toString()},
      );
    }
  }
}
