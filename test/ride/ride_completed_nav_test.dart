import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/app/router/ride_navigator.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

/// Focused nav contracts: RideCompleted Done/Back → home, Waiting → complete.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AppScope.instance.ride
      ..rideId = null
      ..status = RideStatus.idle;
  });

  Future<void> phone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  test('RideCompleted Done and Back call RideNavigator.home', () {
    final src = File(
      'lib/features/ride_complete/presentation/ride_completed.dart',
    ).readAsStringSync();
    expect(src.contains("import 'package:movera_rider/app/router/ride_navigator.dart';"),
        isTrue);
    expect(src.contains('centerContent: "Done"'), isTrue);
    expect(src.contains('RideNavigator.home'), isTrue);
    expect(
      src.contains('CustomButton(centerContent: "Done", onPressed: () {})'),
      isFalse,
    );
    expect(
      src.contains("onPressed: () => RideNavigator.home(context)"),
      isTrue,
    );
    // Back affordance (first InkWell) also uses home, not Navigator.pop.
    final backStart = src.indexOf('InkWell(');
    expect(backStart, greaterThanOrEqualTo(0));
    final backEnd = src.indexOf('You', backStart);
    final back = src.substring(backStart, backEnd);
    expect(back.contains('RideNavigator.home(context)'), isTrue);
    expect(back.contains('Navigator.pop'), isFalse);
  });

  testWidgets('Done-style home clears a locked ride route back to Home', (
    tester,
  ) async {
    await phone(tester);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: moveraNavigatorKey,
        home: const Scaffold(body: Text('home-root')),
      ),
    );
    final nav = moveraNavigatorKey.currentState!;
    nav.push(
      MaterialPageRoute<void>(
        builder: (context) {
          return PopScope(
            canPop: false,
            child: Scaffold(
              body: Column(
                children: [
                  const Text('ride-completed'),
                  TextButton(
                    onPressed: () => RideNavigator.home(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ride-completed'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('home-root'), findsOneWidget);
    expect(find.text('ride-completed'), findsNothing);
    expect(nav.canPop(), isFalse);
  });

  test('Waiting listens for completed surface and replaces with RideCompleted',
      () {
    final src = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();
    expect(src.contains('_maybeOpenCompleted'), isTrue);
    expect(src.contains('isCompletedSurface'), isTrue);
    expect(src.contains('Navigator.pushReplacement'), isTrue);
    expect(src.contains('RideCompleted()'), isTrue);
    expect(src.contains('markCompleted'), isTrue);
  });
}
