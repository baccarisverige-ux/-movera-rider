import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/core/notifications/push_payload.dart';
import 'package:movera_rider/features/notifications/application/notification_navigation.dart';
import 'package:movera_rider/features/notifications/application/notifications_controller.dart';
import 'package:movera_rider/features/notifications/data/notifications_repository.dart';
import 'package:movera_rider/features/notifications/presentation/notifications.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NAV-2 / NAV-8 / NAV-10: notification and Safety openers.
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    RideRestoreCoordinator.instance.authRootShowing = false;
  });
  tearDown(() => RideRestoreCoordinator.instance.authRootShowing = false);

  testWidgets('nothing opens over Sign in', (tester) async {
    await _pumpApp(tester, const Text('SIGN-IN-ROOT'));
    RideRestoreCoordinator.instance.authRootShowing = true;

    expect(pushPageOnce(() => const Text('SAFETY'), AppRoutes.safety), isFalse);
    expect(await openRideFromNotification('ride_x'), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('SAFETY'), findsNothing);
    expect(moveraNavigatorKey.currentState!.canPop(), isFalse);
  });

  testWidgets('a repeated open does not stack a second copy', (tester) async {
    await _pumpApp(tester, const Text('HOME-ROOT'));
    expect(pushPageOnce(() => const Text('SAFETY'), AppRoutes.safety), isTrue);
    await tester.pumpAndSettle();
    expect(pushPageOnce(() => const Text('SAFETY'), AppRoutes.safety), isTrue);
    await tester.pumpAndSettle();

    moveraNavigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('SAFETY'), findsNothing);
    expect(find.text('HOME-ROOT'), findsOneWidget);
  });

  testWidgets('an ended ride row says so, and a double tap opens once', (
    tester,
  ) async {
    final store = NotificationsRepository();
    final controller = NotificationsController(store: store);
    controller.ingest(
      const PushPayload(
        type: 'ride.completed',
        title: 'Ride finished',
        body: 'Thanks for riding.',
        messageId: 'nav10',
        rideId: 'ride-ended',
      ),
      read: false,
    );
    var calls = 0;
    final gate = Completer<bool>();
    await _pumpApp(
      tester,
      NotificationScreen(
        controller: controller,
        openRide: (_) {
          calls += 1;
          return gate.future;
        },
      ),
    );

    await tester.tap(find.text('Ride finished'));
    await tester.pump();
    await tester.tap(find.text('Ride finished'));
    await tester.pump();
    expect(calls, 1);

    gate.complete(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('This ride has ended.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('a ride with no live snapshot reports nothing to open', (
    tester,
  ) async {
    await _pumpApp(tester, const Text('HOME-ROOT'));
    final opened = await tester.runAsync(
      () => openRideFromNotification('ride_gone'),
    );
    expect(opened, isFalse);
  });
}
