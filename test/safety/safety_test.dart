import 'dart:ui' show SemanticsAction, SemanticsFlag;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/core/api/safety_mock_api.dart';
import 'package:movera_rider/core/permissions/permission_service.dart';
import 'package:movera_rider/features/safety/application/emergency_call_service.dart';
import 'package:movera_rider/features/safety/application/safety_audio_service.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/data/safety_data_sources.dart';
import 'package:movera_rider/features/safety/data/safety_repository.dart';
import 'package:movera_rider/features/safety/data/safety_store.dart';
import 'package:movera_rider/features/safety/domain/emergency_contact.dart';
import 'package:movera_rider/features/safety/domain/phone_e164.dart';
import 'package:movera_rider/features/safety/domain/ride_check.dart';
import 'package:movera_rider/features/safety/domain/ride_pin.dart';
import 'package:movera_rider/features/safety/domain/safety_event.dart';
import 'package:movera_rider/features/safety/domain/safety_preferences.dart';
import 'package:movera_rider/features/safety/domain/trip_share.dart';
import 'package:movera_rider/features/safety/presentation/pin_verification_page.dart';
import 'package:movera_rider/features/safety/presentation/safety_hub.dart';
import 'package:shared_preferences/shared_preferences.dart';

SafetyController buildController({SafetyStore? store}) {
  resetSafetyMockForProcess();
  SafetyStore.resetShared();
  SafetyRepository.resetShared();
  SafetyController.resetShared();
  final client = InProcessMockClient();
  final session = store ??
      SafetyStore(
        local: PreferencesSafetyLocalDataSource(memoryOnly: true),
        remote: ApiSafetyRemoteDataSource(ApiClient(client: client)),
      );
  return SafetyController(session: session);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    resetSafetyMockForProcess();
    SafetyStore.resetShared();
    SafetyRepository.resetShared();
    SafetyController.resetShared();
  });

  test('Waiting maskedCall still records on shared repository', () {
    SafetyController().record(SafetyKind.maskedCall);
    expect(SafetyController().events.single.kind, SafetyKind.maskedCall);
  });

  testWidgets('Safety Hub opens and loads persisted state', (tester) async {
    final ctl = buildController();
    await ctl.load();
    await tester.pumpWidget(MaterialApp(home: SafetyHub(controller: ctl)));
    await tester.pumpAndSettle();
    expect(find.text('Safety preferences'), findsOneWidget);
    expect(find.text('PIN verification'), findsOneWidget);
    for (final label in const [
      'PIN verification',
      'Emergency contacts',
      'Share trip status',
      'RideCheck',
    ]) {
      final data =
          tester.getSemantics(find.bySemanticsLabel(label)).getSemanticsData();
      expect(data.label, label, reason: label);
      expect(
        data.hasFlag(SemanticsFlag.isButton),
        isTrue,
        reason: '$label should be a button',
      );
      expect(
        data.hasAction(SemanticsAction.tap),
        isTrue,
        reason: '$label should be actionable',
      );
    }
    expect(find.text('Call 112'), findsNothing);
    expect(find.text('Record audio'), findsNothing);
    await tester.pumpWidget(MaterialApp(home: SafetyHub(controller: ctl)));
    await tester.pumpAndSettle();
    expect(find.text('Safety preferences'), findsOneWidget);
  });

  testWidgets('every Safety Hub row opens its real destination page', (
    tester,
  ) async {
    for (final route in const <(String, String)>[
      ('PIN verification', 'Verify rides with a PIN'),
      ('Emergency contacts', 'No emergency contacts yet'),
      ('Share trip status', 'Trip sharing'),
      ('RideCheck', 'RideCheck alerts'),
    ]) {
      final ctl = buildController();
      await ctl.load();
      await tester.pumpWidget(MaterialApp(home: SafetyHub(controller: ctl)));
      await tester.pumpAndSettle();

      final row = find.bySemanticsLabel(route.$1);
      expect(row, findsOneWidget, reason: route.$1);
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(find.text(route.$2), findsOneWidget, reason: route.$1);
    }
  });

  testWidgets('PIN page shows a framed 4-digit cadre', (tester) async {
    final ctl = buildController();
    await ctl.load();
    await tester.pumpWidget(MaterialApp(home: PinVerificationPage(controller: ctl)));
    await tester.pumpAndSettle();
    expect(find.text('YOUR PIN'), findsOneWidget);
    expect(find.text('Verify rides with a PIN'), findsOneWidget);
    expect(find.text('Change PIN'), findsOneWidget);
    for (final digit in ctl.pin.pin.split('')) {
      expect(find.text(digit), findsWidgets);
    }
  });

  test('PIN generate enable disable rotate persist and verify', () async {
    final ctl = buildController();
    await ctl.load();
    expect(ctl.preferences.pinRequired, isFalse);
    expect(RegExp(r'^\d{4}$').hasMatch(ctl.pin.pin), isTrue);
    final first = ctl.pin.pin;
    await ctl.setPinRequired(true);
    expect(ctl.preferences.pinRequired, isTrue);
    await ctl.rotatePin();
    expect(ctl.pin.pin.length, 4);
    expect(ctl.pin.pin, isNot(first));
    expect((await ctl.verifyPin(rideId: 'ride_1', pin: ctl.pin.pin)).valid, isTrue);
    final other = ctl.pin.pin == '0000' ? '1111' : '0000';
    expect((await ctl.verifyPin(rideId: 'ride_1', pin: other)).valid, isFalse);
    await ctl.setPinRequired(false);
    expect(ctl.preferences.pinRequired, isFalse);
  });

  test('PIN DTO parsing', () {
    final parsed = RidePin.fromJson({
      'pinId': 'pin_1',
      'userId': 'rider-local',
      'pin': '4242',
      'required': true,
      'version': 2,
    });
    expect(parsed.pin, '4242');
    expect(parsed.requiredForStart, isTrue);
    expect(RidePin.fromJson({'pin': 'nope'}).pin.length, 4);
    expect(SafetyPreferences.fromJson(null).pinRequired, isFalse);
  });

  test('emergency contacts CRUD primary duplicate and invalid phone', () async {
    final ctl = buildController();
    await ctl.load();
    await ctl.addContact(name: 'Sam', phone: '0701111111', relationship: 'Friend');
    expect(ctl.contacts.single.isPrimary, isTrue);
    expect(ctl.contacts.single.phoneE164, '+46701111111');
    await ctl.addContact(name: 'Kim', phone: '+46702222222', relationship: 'Family');
    expect(ctl.contacts, hasLength(2));
    final kim = ctl.contacts.firstWhere((c) => c.name == 'Kim');
    await ctl.makePrimary(kim.id);
    expect(ctl.contacts.where((c) => c.isPrimary).single.name, 'Kim');
    expect(
      () => ctl.addContact(name: 'Dup', phone: '0701111111'),
      throwsA(isA<SafetyException>()),
    );
    expect(
      () => ctl.addContact(name: 'Bad', phone: '123'),
      throwsA(isA<SafetyException>()),
    );
    await ctl.removeContact(ctl.contacts.firstWhere((c) => c.name == 'Sam').id);
    expect(ctl.contacts, hasLength(1));
    expect(ctl.contacts.single.isPrimary, isTrue);
  });

  test('max 5 contacts', () async {
    final ctl = buildController();
    await ctl.load();
    for (var i = 0; i < 5; i++) {
      await ctl.addContact(name: 'C$i', phone: '070100000$i');
    }
    expect(
      () => ctl.addContact(name: 'Extra', phone: '0709999999'),
      throwsA(isA<SafetyException>()),
    );
  });

  test('SwedishPhone E.164', () {
    expect(SwedishPhone.toE164('0701234567'), '+46701234567');
    expect(SwedishPhone.toE164('+46 70-123 45 67'), '+46701234567');
    expect(SwedishPhone.toE164('0046701234567'), '+46701234567');
    expect(SwedishPhone.toE164('123'), isNull);
  });

  test('trip share preferences start stop without fake URL', () async {
    final ctl = buildController();
    await ctl.load();
    await ctl.setTripShare(enabled: true, mode: TripShareMode.auto);
    expect(ctl.preferences.tripShareEnabled, isTrue);
    expect(
      () => ctl.startShare(''),
      throwsA(isA<SafetyException>()),
    );
    final share = await ctl.startShare('ride_qa');
    expect(share.isActive, isTrue);
    expect(share.shareToken, isNotNull);
    expect(share.shareToken!.startsWith('http'), isFalse);
    await ctl.stopShare('ride_qa');
  });

  test('expired share DTO', () {
    final share = TripShare.fromJson({
      'shareId': 's1',
      'rideId': 'r1',
      'userId': 'rider-local',
      'isActive': true,
      'expiresAt': DateTime.now().toUtc().subtract(const Duration(hours: 1)).toIso8601String(),
    });
    expect(share.expired, isTrue);
  });

  test('RideCheck enable deterministic events duplicate stale resolve', () async {
    final ctl = buildController();
    await ctl.load();
    await ctl.setRideCheck(true);
    expect(ctl.rideCheckPolicy.enabled, isTrue);
    final first = await ctl.rideCheck.unexpectedStop();
    final dup = await ctl.rideCheck.simulate(
      type: RideCheckEventType.unexpectedStop,
      eventId: first.eventId,
    );
    expect(dup.eventId, first.eventId);
    expect(
      ctl.rideCheck.events().where((e) => e.eventId == first.eventId),
      hasLength(1),
    );
    await ctl.rideCheck.resolve(first);
    final stale = await ctl.rideCheck.simulate(
      type: RideCheckEventType.routeDeviation,
      eventId: 'ev_stale',
      at: first.at.subtract(const Duration(minutes: 1)),
    );
    expect(stale.status, RideCheckStatus.stale);
    final live = await ctl.rideCheck.routeDeviation();
    expect(live.status, RideCheckStatus.pending);
  });

  test('emergency call is never automatic', () async {
    final dialer = RecordingEmergencyDialer();
    final service = EmergencyCallService(dialer: dialer);
    expect(service.explicitCallCount, 0);
    expect(dialer.calls, isEmpty);
    await service.callEmergencyNumber();
    expect(dialer.calls, ['112']);
    expect(service.explicitCallCount, 1);
  });

  test('audio start stop delete permission and web fallback', () async {
    resetSafetyMockForProcess();
    final store = SafetyStore(
      local: PreferencesSafetyLocalDataSource(memoryOnly: true),
      remote: ApiSafetyRemoteDataSource(ApiClient(client: InProcessMockClient())),
    );
    await store.load();
    final perms = PermissionService();
    final audio = SafetyAudioService(permissions: perms, store: store);
    expect(() => audio.start(), throwsA(isA<SafetyAudioException>()));
    audio.grantMicrophone();
    final rec = await audio.start(rideId: 'ride_a');
    expect(audio.isRecording, isTrue);
    expect(rec.localPath, isNotNull);
    final stopped = await audio.stop();
    expect(stopped.endedAt, isNotNull);
    await audio.delete(stopped);

    final unsupported = SafetyAudioService(
      permissions: PermissionService()
        ..set(AppPermission.microphone, PermissionPhase.granted),
      store: store,
      supported: false,
    );
    expect(() => unsupported.start(), throwsA(isA<SafetyAudioException>()));
  });

  test('optimistic write rolls back on simulated server failure', () async {
    resetSafetyMockForProcess();
    final store = SafetyStore(
      local: PreferencesSafetyLocalDataSource(memoryOnly: true),
      remote: ApiSafetyRemoteDataSource(ApiClient(client: InProcessMockClient())),
    );
    await store.load();
    expect(store.preferences.pinRequired, isFalse);
    store.failNextWrite = true;
    await expectLater(
      store.patchPreferences(store.preferences.copyWith(pinRequired: true)),
      throwsA(isA<SafetyException>()),
    );
    expect(store.preferences.pinRequired, isFalse);
  });

  test('rotate PIN idempotency key returns same mock payload', () async {
    resetSafetyMockForProcess();
    final client = InProcessMockClient();
    final api = ApiClient(client: client);
    final first = await api.post('/api/v1/safety/pin/rotate', idempotencyKey: 'safety-pin-same');
    final second = await api.post('/api/v1/safety/pin/rotate', idempotencyKey: 'safety-pin-same');
    expect(first['pin']['pinId'], second['pin']['pinId']);
  });

  test('malformed safety DTOs do not throw', () {
    expect(SafetyPreferences.fromJson({'tripShareMode': 1}).tripShareMode, TripShareMode.manual);
    expect(RideCheckEvent.fromJson({}).type, RideCheckEventType.manualSafetyCheck);
    expect(EmergencyContact.fromJson({}).name, '');
  });
}
