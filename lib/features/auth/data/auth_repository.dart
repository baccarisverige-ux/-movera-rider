import 'package:movera_rider/app/di.dart';

class AuthRepository {
  Future<void> signIn({required String provider}) {
    return AppScope.instance.tokens.save(
      access: 'movera-mock-$provider',
      refresh: 'movera-mock-refresh',
    );
  }

  Future<void> signOut() => AppScope.instance.tokens.clear();
}
