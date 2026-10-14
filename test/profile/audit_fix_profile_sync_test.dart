import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/data/synced_profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Counts PATCH /rider/profile calls and can refuse the next ones.
class _ProfileServer extends InProcessMockClient {
  int patches = 0;
  bool down = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.method == 'PATCH' &&
        request.url.path == SyncedProfileRepository.path) {
      patches++;
      if (down) failNext = true;
    }
    return super.send(request);
  }
}

/// FLOW-7: the rider's name, language and consents reach the server; the
/// device copy is only the cache.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const demo = AppEnv(
    flavor: AppFlavor.demo,
    apiBaseUrl: 'https://api.demo.movera.invalid',
  );

  test(
    'saving the profile sends one PATCH with name, language and consents',
    () async {
      final server = _ProfileServer();
      final controller = ProfileController(
        store: SyncedProfileRepository(
          api: ApiClient(client: server, env: demo),
        ),
      );
      await controller.hydrate();
      await controller.update(
        controller.profile.copyWith(
          name: 'Ada Lovelace',
          language: 'Svenska',
          promotions: true,
          emailUpdates: false,
        ),
      );
      expect(server.patches, 1);
      expect(server.riderProfile?['name'], 'Ada Lovelace');
      expect(server.riderProfile?['language'], 'Svenska');
      expect(server.riderProfile?['consents'], {
        'rideUpdates': true,
        'emailUpdates': false,
        'promotions': true,
      });
      expect(controller.profile.firstName, 'Ada');
    },
  );

  test(
    'a save that does not reach the server is kept and sent again',
    () async {
      final server = _ProfileServer()..down = true;
      final repository = SyncedProfileRepository(
        api: ApiClient(client: server, env: demo),
      );
      final controller = ProfileController(store: repository);
      await controller.update(controller.profile.copyWith(name: 'Grace'));
      expect(controller.profile.name, 'Grace');
      expect(repository.syncPending, isTrue);
      expect(server.riderProfile, isNull);

      server.down = false;
      await controller.hydrate();
      expect(repository.syncPending, isFalse);
      expect(server.riderProfile?['name'], 'Grace');
    },
  );

  test('the app profile is the synced one in every flavor', () {
    final scope = AppScope.composeForEnvironment(demo);
    addTearDown(scope.disposeForTest);
    expect(scope.profile.repository, isA<SyncedProfileRepository>());
  });
}
