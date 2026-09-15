import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/notifications/application/notifications_controller.dart';
import 'package:movera_rider/features/notifications/data/notifications_repository.dart';
import 'package:movera_rider/features/notifications/presentation/notifications.dart';

void main() {
  test('fresh notifications feed contains no seeded demo events', () {
    final repository = NotificationsRepository();
    final controller = NotificationsController(store: repository);

    expect(repository.all(), isEmpty);
    expect(controller.feed(), isEmpty);
  });

  testWidgets('notifications screen shows honest empty state', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Notification'), findsOneWidget);
    expect(find.text('No notifications yet'), findsOneWidget);
    expect(
      find.text('Ride and account updates will appear here when available.'),
      findsOneWidget,
    );

    expect(find.text('Driver assigned'), findsNothing);
    expect(find.text('mac is on the way'), findsNothing);
    expect(find.text(r'$10.00 Paid'), findsNothing);
    expect(find.text('2min ago'), findsNothing);
  });
}
