import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/features/active_ride/presentation/driver_call_unavailable_dialog.dart';
import 'package:movera_rider/features/active_ride/presentation/rider_in_trip_panel.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_sheet_bits.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/safety/application/emergency_call_service.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/data/safety_data_sources.dart';
import 'package:movera_rider/features/safety/data/safety_store.dart';
import 'package:movera_rider/features/safety/domain/safety_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('real emergency adapter requests the platform tel:112 URI', () async {
    Uri? launched;
    final dialer = SystemEmergencyDialer(
      launcher: (uri) async {
        launched = uri;
        return true;
      },
    );
    final service = EmergencyCallService(dialer: dialer);

    await service.callEmergencyNumber();

    expect(launched, Uri(scheme: 'tel', path: '112'));
    expect(service.explicitCallCount, 1);
  });

  test('real emergency adapter fails when platform refuses the tel URI', () async {
    final dialer = SystemEmergencyDialer(
      launcher: (_) async => false,
    );

    await expectLater(
      dialer.open('112'),
      throwsA(isA<EmergencyCallException>()),
    );
  });

  test('SOS records locally and posts through the safety backend contract', () async {
    final store = SafetyStore(
      local: PreferencesSafetyLocalDataSource(memoryOnly: true),
      remote: ApiSafetyRemoteDataSource(
        ApiClient(client: InProcessMockClient()),
      ),
    );
    final controller = SafetyController(session: store);
    await controller.load();

    await controller.sos(rideId: 'ride_phase71');

    expect(
      controller.events.any(
        (event) =>
            event.kind == SafetyKind.sos && event.rideId == 'ride_phase71',
      ),
      isTrue,
    );
    final backendEvents = controller.rideCheck.events();
    expect(
      backendEvents.any(
        (event) =>
            event.rideId == 'ride_phase71' &&
            event.payload['kind'] == 'sos' &&
            event.payload['action'] == 'call_112',
      ),
      isTrue,
    );
  });

  testWidgets('waiting driver call is explicitly unavailable', (tester) async {
    await _pump(
      tester,
      Builder(
        builder: (context) => WaitingDriverCard(
          driver: _driver,
          rideId: 'ride_waiting',
          onOpenProfile: () {},
          onCall: () => showDriverCallUnavailable(
            context,
            driverName: _driver.firstName,
          ),
          onMore: () {},
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Call driver'));
    await tester.pumpAndSettle();

    expect(find.text('Driver calling unavailable'), findsOneWidget);
    expect(
      find.textContaining('masked calling number'),
      findsOneWidget,
    );
  });

  testWidgets('in-trip driver call is explicitly unavailable', (tester) async {
    await _pump(
      tester,
      Builder(
        builder: (context) => RiderInTripPanel(
          destinationAddress: 'Centralstation',
          rideType: 'Movera',
          paymentMethod: 'card',
          price: 190,
          driver: _driver,
          rideId: 'ride_in_trip',
          onOpenProfile: () {},
          onCall: () => showDriverCallUnavailable(
            context,
            driverName: _driver.firstName,
          ),
          onMore: () {},
          onCancel: () {},
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Call driver'));
    await tester.pumpAndSettle();

    expect(find.text('Driver calling unavailable'), findsOneWidget);
    expect(find.textContaining('masked calling number'), findsOneWidget);
  });
}

const _driver = MatchedDriver(
  id: 'driver_phase71',
  firstName: 'Alex',
  vehicleMake: 'Volvo',
  vehicleModel: 'EX30',
  plate: 'ABC 123',
);

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: Scaffold(body: child),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
