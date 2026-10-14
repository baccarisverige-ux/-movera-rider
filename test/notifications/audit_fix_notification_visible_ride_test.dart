import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/features/notifications/application/notification_navigation.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NAV-2: opening the notification of the ride already on screen keeps that
/// screen. Uses only APIs that exist at the audited commit.
class _RideStage extends StatefulWidget {
  const _RideStage({super.key});

  @override
  State<_RideStage> createState() => _RideStageState();
}

class _RideStageState extends State<_RideStage> {
  @override
  Widget build(BuildContext context) => const Text('RIDE-STAGE');
}

Future<void> _pumpApp(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) =>
          MaterialApp(navigatorKey: moveraNavigatorKey, home: home),
    ),
  );
  await tester.pump();
}

Future<void> _push(String name, Widget page, WidgetTester tester) async {
  unawaited(
    moveraNavigatorKey.currentState!.push<void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: name),
        builder: (_) => page,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('opening the visible ride keeps its screen mounted', (
    tester,
  ) async {
    await RideSnapshotStore.save(
      RideSnapshot(
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
        rideId: 'ride_nav2',
      ),
    );
    final stageKey = GlobalKey<_RideStageState>();
    await _pumpApp(tester, const Text('HOME-ROOT'));
    await _push(AppRoutes.waitingForDriver, _RideStage(key: stageKey), tester);
    final before = stageKey.currentState;
    await _push(AppRoutes.notifications, const Text('LIST'), tester);

    final opened = await tester.runAsync(
      () => openRideFromNotification('ride_nav2').timeout(
        // The old opener tore the stack down and then waited for a frame
        // that never comes inside runAsync; fail instead of hanging.
        const Duration(seconds: 10),
        onTimeout: () => false,
      ),
    );
    await tester.pumpAndSettle();

    expect(opened, isTrue);
    expect(find.text('LIST'), findsNothing);
    expect(stageKey.currentState, same(before));
    expect(find.text('RIDE-STAGE'), findsOneWidget);
  });
}
