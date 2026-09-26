import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/features/profile/application/account_security_controller.dart';
import 'package:movera_rider/features/profile/data/account_security_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const env = AppEnv(
    flavor: AppFlavor.test,
    apiBaseUrl: 'https://api.test.movera.invalid',
    mapsEnabled: true,
  );

  test('verification truth comes from backend metadata, not contact strings', () async {
    final repo = AccountSecurityRepository(
      api: ApiClient(
        env: env,
        client: InProcessMockClient(),
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
        client: InProcessMockClient(),
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
        client: InProcessMockClient(),
      ),
    );

    final before = await repo.load();
    expect(before.sessions.where((item) => !item.current), isNotEmpty);
    expect(before.capabilities.signOutOtherDevices, isTrue);

    final after = await repo.signOutOtherDevices();

    expect(after.sessions, isNotEmpty);
    expect(after.sessions.every((item) => item.current), isTrue);
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
