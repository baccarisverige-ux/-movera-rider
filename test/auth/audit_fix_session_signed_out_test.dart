import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/features/auth/presentation/auth_navigation.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_booking/presentation/ride_restore_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NAV-1 / FLOW-10: root swaps close the auth routes above the gate, and a
/// missing session keeps the live ride without drawing it over Sign in.
RideSnapshot _snapshot() => RideSnapshot(
  status: RideStatus.driverArriving,
  savedAt: DateTime.now(),
  pickupAddress: 'Pickup',
  destinationAddress: 'Destination',
  pickupLat: 59.33,
  pickupLng: 18.06,
  destinationLat: 59.34,
  destinationLng: 18.08,
  rideType: 'Movera',
  price: 180,
  paymentMethod: 'card',
  rideId: 'ride_flow10',
);

Future<void> _pumpGate(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 932);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  debugDefaultTargetPlatformOverride = TargetPlatform.linux;
  addTearDown(() => debugDefaultTargetPlatformOverride = null);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        navigatorKey: moveraNavigatorKey,
        home: RideRestoreGate(key: RideRestoreGate.gateKey),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));
}

Future<void> _unmount(WidgetTester tester) async {
  RideRestoreCoordinator.instance.showing = RestoredSurface.home;
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
  debugDefaultTargetPlatformOverride = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('sign-in keeps the root gate and its hook live', (tester) async {
    await _pumpGate(tester);
    enterMoveraApp(moveraNavigatorKey.currentState!.context);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(RideRestoreGate), findsOneWidget);
    final swapped = RideRestoreCoordinator.instance.replaceRootSurface(
      const Text('RESTORED-RIDE-SURFACE', textDirection: TextDirection.ltr),
      RestoredSurface.waiting,
    );
    await tester.pump();
    expect(swapped, isTrue);
    expect(find.text('RESTORED-RIDE-SURFACE'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('sign-in from a pushed auth screen pops back to the gate', (
    tester,
  ) async {
    await _pumpGate(tester);
    moveraNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => const Text('PHONE-VERIFY')),
    );
    await tester.pump(const Duration(milliseconds: 400));
    showMoveraRoot(const Text('ROOT-PAGE', textDirection: TextDirection.ltr));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('PHONE-VERIFY'), findsNothing);
    expect(find.text('ROOT-PAGE'), findsOneWidget);
    expect(moveraNavigatorKey.currentState!.canPop(), isFalse);
    await _unmount(tester);
  });

  test('missing session keeps the live ride and does not resume it', () async {
    final snapshot = _snapshot();
    await RideSnapshotStore.save(snapshot);
    Widget? shown;
    final coordinator = RideRestoreCoordinator(
      reader: () async => snapshot,
      authRequired: () => true,
      hasSession: () async => false,
      resync: (_) async {},
    );
    coordinator.onReplaceRoot = (page) => shown = page;
    coordinator.debugAtRoot = () => true;

    await coordinator.root();
    expect((await RideSnapshotStore.read())?.rideId, 'ride_flow10');

    expect(await coordinator.resumeIfNeeded(), isNull);
    expect(shown, isNull, reason: 'no ride drawn over Sign in');

    coordinator.authRootShowing = true;
    expect(await coordinator.resumeIfNeeded(), isNull);
    expect(shown, isNull);
  });
}
