import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/app.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/api/api_error.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ARCH-17: DI no longer imports the Sign in screen. The app shell registers
/// the navigation, and a forced sign-out still reaches it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('session expiry runs the navigation the app shell registered', () async {
    final previous = AppScope.showSignInOnSessionExpired;
    addTearDown(() => AppScope.showSignInOnSessionExpired = previous);
    var shown = 0;
    AppScope.showSignInOnSessionExpired = () => shown++;

    await AppScope.instance.tokens.save(
      access: 'hook-expired-access',
      refresh: 'hook-rejected-refresh',
    );
    await expectLater(
      AppScope.instance.api.post(
        '/api/v1/auth/refresh',
        body: {'refreshToken': 'hook-rejected-refresh'},
      ),
      throwsA(isA<ApiError>()),
    );
    expect(shown, 1);
  });

  test('the app shell registration is idempotent and keeps an override', () {
    final previous = AppScope.showSignInOnSessionExpired;
    addTearDown(() => AppScope.showSignInOnSessionExpired = previous);
    AppScope.showSignInOnSessionExpired = null;
    registerSessionExpiredNavigation();
    final registered = AppScope.showSignInOnSessionExpired;
    expect(registered, isNotNull);
    registerSessionExpiredNavigation();
    expect(identical(AppScope.showSignInOnSessionExpired, registered), isTrue);
  });
}
