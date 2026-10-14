import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/features/auth/presentation/auth_navigation.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:movera_rider/features/ride_booking/presentation/ride_restore_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NAV-1: the root RideRestoreGate survives sign-in, and a disposed gate
/// never leaves a dead hook behind. Uses only APIs that exist at the audited
/// commit, so it fails there.
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

  testWidgets('a disposed gate clears the hook; swaps then report false', (
    tester,
  ) async {
    await _pumpGate(tester);
    expect(RideRestoreCoordinator.instance.onReplaceRoot, isNotNull);
    await _unmount(tester);

    expect(RideRestoreCoordinator.instance.onReplaceRoot, isNull);
    expect(
      RideRestoreCoordinator.instance.replaceRootSurface(
        const SizedBox(),
        RestoredSurface.waiting,
      ),
      isFalse,
    );
    RideRestoreCoordinator.instance.showing = RestoredSurface.home;
  });
}
