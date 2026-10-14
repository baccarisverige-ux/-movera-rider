import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/notifications/push_payload.dart';
import 'package:movera_rider/features/notifications/application/notifications_controller.dart';
import 'package:movera_rider/features/notifications/data/notifications_repository.dart';
import 'package:movera_rider/features/notifications/presentation/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FLOW-18: the feed says which day an item is from, and an ended ride's
/// notification opens Ride History instead of doing nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  final now = DateTime(2026, 10, 14, 9, 30);
  NotificationsRepository repo() => NotificationsRepository(now: () => now);

  String labelFor(DateTime sentAt) {
    final store = repo();
    store.ingest(
      PushPayload(type: 'info', title: 'Hi', sentAt: sentAt),
      read: false,
    );
    return store.all().single.time;
  }

  test('today shows the time only', () {
    expect(labelFor(DateTime(2026, 10, 14, 8, 5)), '08:05');
  });

  test('yesterday and older items carry their date', () {
    expect(labelFor(DateTime(2026, 10, 13, 14, 5)), 'Yesterday 14:05');
    expect(labelFor(DateTime(2026, 10, 3, 14, 5)), '3 Oct 14:05');
    expect(labelFor(DateTime(2025, 12, 30, 7, 0)), '30 Dec 2025 07:00');
  });

  test('the item keeps when it was sent', () {
    final store = repo();
    final sent = DateTime(2026, 10, 13, 14, 5);
    store.ingest(
      PushPayload(type: 'info', title: 'Hi', sentAt: sent),
      read: false,
    );
    expect(store.all().single.at, sent);
  });

  testWidgets('an ended ride notification opens Ride History', (tester) async {
    final controller = NotificationsController(store: repo());
    controller.ingest(
      const PushPayload(
        type: 'ride.completed',
        title: 'Ride finished',
        body: 'Thanks for riding.',
        messageId: 'flow18',
        rideId: 'ride-ended',
      ),
      read: false,
    );
    var historyOpened = 0;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: NotificationScreen(
            controller: controller,
            openRide: (_) async => false,
            openHistory: (_) => historyOpened += 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Ride finished'));
    await tester.pump();
    await tester.pump();
    expect(historyOpened, 1);
    await tester.pump(const Duration(seconds: 5));
  });
}
