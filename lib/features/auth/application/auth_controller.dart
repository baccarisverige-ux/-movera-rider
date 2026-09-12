import 'package:movera_rider/features/auth/data/auth_repository.dart';

class AuthController {
  AuthController({AuthRepository? auth}) : _auth = auth ?? AuthRepository();
  final AuthRepository _auth;
  String? lastPhone;

  Future<void> requestOtp({String phone = ''}) async {
    lastPhone = phone;
  }

  Future<void> signIn({required String provider}) =>
      _auth.signIn(provider: provider);

  Future<void> signOut() => _auth.signOut();
}
