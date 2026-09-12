import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/auth/data/auth_repository.dart';

class AuthController {
  AuthController({AuthRepository? auth}) : _auth = auth ?? AuthRepository();
  final AuthRepository _auth;
  String? lastPhone;

  Future<void> requestOtp({String phone = ''}) async {
    lastPhone = phone;
  }

  Future<void> signIn({required String provider}) async {
    await _auth.signIn(provider: provider);
    await AppScope.instance.push.register();
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await AppScope.instance.push.unregister();
  }
}
