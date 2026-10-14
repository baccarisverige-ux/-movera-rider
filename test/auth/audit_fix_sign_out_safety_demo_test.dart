import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/core/api/safety_mock_api.dart';
import 'package:movera_rider/features/safety/data/safety_data_sources.dart';
import 'package:movera_rider/features/safety/data/safety_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PR-9 follow-up to FLOW-9: the demo Safety mock keeps its state in memory
/// and in `movera_safety_demo_v1`. Sign-out must clear both, so the next
/// rider on the device never gets the previous rider's PIN, contacts or
/// settings back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues(<String, String>{});
    SharedPreferences.setMockInitialValues(<String, Object>{});
    resetSafetyMockForProcess();
    await AppScope.instance.tokens.clear();
  });

  // The demo transport: one process-level Safety mock that saves itself.
  final client = InProcessMockClient(persistSafety: true);
  SafetyStore launch() => SafetyStore(
    local: PreferencesSafetyLocalDataSource(memoryOnly: true),
    remote: ApiSafetyRemoteDataSource(ApiClient(client: client)),
  );

  Future<String?> savedDemoState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs.getString(SafetyMockApi.storageKey);
  }

  test('sign-out: the next rider sees none of the old Safety data', () async {
    final riderA = launch();
    await riderA.load();
    await riderA.createContact(name: 'Kim', phone: '0701234567');
    await riderA.patchPreferences(
      riderA.preferences.copyWith(pinRequired: true),
    );
    final oldPin = riderA.pin.pin;
    expect(oldPin, isNotEmpty);
    expect(await savedDemoState(), contains('Kim'));

    await AppScope.instance.tokens.save(access: 'a', refresh: 'b');
    await AppScope.instance.auth.signOut();

    // The saved demo state is gone and nothing in memory writes it back.
    expect(await savedDemoState(), isNull);
    expect(client.safety.contacts, isEmpty);
    expect(client.safety.preferences['pinRequired'], isFalse);

    final riderB = launch();
    await riderB.load();
    expect(riderB.contacts, isEmpty);
    expect(riderB.preferences.pinRequired, isFalse);
    expect(riderB.pin.pin, isNot(oldPin));
    final saved = await savedDemoState();
    expect(saved, isNot(contains('Kim')));
    expect(saved, isNot(contains(oldPin)));
  });

  test(
    'a save already under way when the rider signs out is dropped',
    () async {
      final mock = client.safety;
      mock.contacts.add({'id': 'ec_old', 'name': 'Kim'});
      final pending = mock.persist();
      mock.reset();
      await pending;
      expect(await savedDemoState(), isNull);
    },
  );

  test('defaults after reset are the same as a fresh mock', () {
    final mock = SafetyMockApi()
      ..preferences['tripShareEnabled'] = true
      ..rideCheck = {'enabled': true}
      ..reset();
    final fresh = SafetyMockApi();
    expect(mock.preferences, fresh.preferences);
    expect(mock.rideCheck, fresh.rideCheck);
    expect(mock.contacts, isEmpty);
  });
}
