import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/features/profile/application/account_security_controller.dart';
import 'package:movera_rider/features/profile/data/account_security_repository.dart';
import 'package:movera_rider/features/profile/data/profile_repository.dart';
import 'package:movera_rider/features/profile/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movera_rider/features/profile/data/profile_repository.dart';
import 'package:movera_rider/features/profile/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  const env = AppEnv(
    flavor: AppFlavor.test,
    apiBaseUrl: 'https://api.test.movera.invalid',
    mapsEnabled: true,
  );

  InProcessMockClient seededSecurityClient({bool withOtherSession = true}) {
    final client = InProcessMockClient();
    client.accountSecurity
      ..['phone'] = '+46701234567'
      ..['email'] = 'rider@example.test'
      ..['phoneVerifiedAt'] = null
      ..['emailVerifiedAt'] = '2026-01-01T12:00:00.000Z'
      ..['sessions'] = [
        {
          'id': 'session_current',
          'device': 'This device',
          'place': 'Stockholm, Sweden',
          'source': 'Movera',
          'current': true,
        },
        if (withOtherSession)
          {
            'id': 'session_other',
            'device': 'Other device',
            'place': 'Stockholm, Sweden',
            'source': 'Movera',
            'current': false,
          },
      ];
    return client;
  }

  test('verification truth comes from backend metadata, not contact strings', () async {
    final repo = AccountSecurityRepository(
      api: ApiClient(
        env: env,
        client: seededSecurityClient(),
      ),
    );

    final state = await repo.load();

    expect(state.phone, '+46701234567');
    expect(state.phoneVerifiedAt, isNull);
    expect(state.phoneVerified, isFalse);
    expect(state.email, 'rider@example.test');
    expect(state.emailVerifiedAt, isNotNull);
    expect(state.emailVerified, isTrue);
  });

  test('unsupported security commands are advertised as unavailable', () async {
    final repo = AccountSecurityRepository(
      api: ApiClient(
        env: env,
        client: seededSecurityClient(),
      ),
    );

    final state = await repo.load();

    expect(state.capabilities.passkeys, isFalse);
    expect(state.capabilities.password, isFalse);
    expect(state.capabilities.authenticator, isFalse);
    expect(state.capabilities.twoStep, isFalse);
    expect(state.capabilities.recoveryPhone, isFalse);
    expect(state.capabilities.connectedAccounts, isFalse);
  });

  test('sign out other devices is verified by refreshed server sessions', () async {
    final repo = AccountSecurityRepository(
      api: ApiClient(
        env: env,
        client: seededSecurityClient(),
      ),
    );

    final before = await repo.load();
    expect(before.sessions.where((item) => !item.current), isNotEmpty);
    expect(before.capabilities.signOutOtherDevices, isTrue);

    final after = await repo.signOutOtherDevices();

    expect(after.sessions, isNotEmpty);
    expect(after.sessions.every((item) => item.current), isTrue);
  });

  test('SharedPreferences cannot persist a successful security state', () async {
    const key = 'phase74_local_profile';
    final store = ProfileRepository(storageKey: key);

    await store.save(
      RiderProfileData.defaults().copyWith(
        phone: '+46709999999',
        email: 'local@example.test',
        twoStepEnabled: true,
        passkeyEnabled: true,
        authenticatorEnabled: true,
        recoveryPhone: '+46708888888',
        googleConnected: true,
        appleConnected: true,
        logins: const [
          LoginSession(
            device: 'Fake device',
            place: 'Local',
            source: 'Preferences',
          ),
        ],
      ),
    );

    final reloaded = ProfileRepository(storageKey: key);
    await reloaded.hydrate();

    expect(reloaded.current.phone, '+46709999999');
    expect(reloaded.current.email, 'local@example.test');
    expect(reloaded.current.twoStepEnabled, isFalse);
    expect(reloaded.current.passkeyEnabled, isFalse);
    expect(reloaded.current.authenticatorEnabled, isFalse);
    expect(reloaded.current.recoveryPhone, isNull);
    expect(reloaded.current.googleConnected, isFalse);
    expect(reloaded.current.appleConnected, isFalse);
    expect(reloaded.current.logins, isEmpty);
  });

  test('local profile persistence scrubs every security claim', () async {
    final store = ProfileRepository(storageKey: 'phase74_profile');
    final unsafe = RiderProfileData.defaults().copyWith(
      passkeyEnabled: true,
      twoStepEnabled: true,
      authenticatorEnabled: true,
      passwordUpdatedAt: DateTime.utc(2026, 1, 1),
      recoveryPhone: '+46709999999',
      googleConnected: true,
      appleConnected: true,
      logins: const [
        LoginSession(
          device: 'Other device',
          place: 'Stockholm',
          source: 'Movera',
        ),
      ],
    );

    final saved = await store.save(unsafe);

    expect(saved.passkeyEnabled, isFalse);
    expect(saved.twoStepEnabled, isFalse);
    expect(saved.authenticatorEnabled, isFalse);
    expect(saved.passwordUpdatedAt.millisecondsSinceEpoch, 0);
    expect(saved.recoveryPhone, isNull);
    expect(saved.googleConnected, isFalse);
    expect(saved.appleConnected, isFalse);
    expect(saved.logins, isEmpty);

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('phase74_profile') ?? '';
    expect(raw, isNot(contains('passkeyEnabled')));
    expect(raw, isNot(contains('twoStepEnabled')));
    expect(raw, isNot(contains('authenticatorEnabled')));
    expect(raw, isNot(contains('recoveryPhone')));
    expect(raw, isNot(contains('googleConnected')));
    expect(raw, isNot(contains('appleConnected')));
    expect(raw, isNot(contains('logins')));
  });

  test('missing security endpoint becomes unavailable instead of local success', () async {
    final controller = AccountSecurityController(
      repository: AccountSecurityRepository(
        api: ApiClient(
          env: env,
          client: _Always404Client(),
        ),
      ),
    );

    await controller.load();

    expect(controller.available, isFalse);
    expect(controller.state, isNull);
    expect(controller.errorMessage, isNotNull);
  });
}

class _Always404Client extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream<List<int>>.value(
        '{"code":"NOT_FOUND","message":"Unknown route"}'.codeUnits,
      ),
      404,
      headers: const {'content-type': 'application/json'},
    );
  }
}
