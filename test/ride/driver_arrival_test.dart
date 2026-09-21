import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/active_ride/presentation/driver_arrived_sheet.dart';

void main() {
  testWidgets('arrival popup sends rider on-the-way reply before closing', (
    WidgetTester tester,
  ) async {
    var replied = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () {
                showDriverArrivedSheet(
                  context,
                  onWay: () async {
                    replied = true;
                  },
                );
              },
              child: const Text('Open arrival'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open arrival'));
    await tester.pumpAndSettle();
    expect(find.text('Your driver is here'), findsOneWidget);
    expect(find.text("I'm on the way"), findsOneWidget);

    await tester.tap(find.text("I'm on the way"));
    await tester.pumpAndSettle();

    expect(replied, isTrue);
    expect(find.text('Your driver is here'), findsNothing);
  });

  test('driver card fields come from the match payload', () {
    const driver = MatchedDriver(
      id: 'drv_1',
      firstName: 'Alex',
      rating: 4.92,
      tripCount: 1284,
      vehicleMake: 'Volvo',
      vehicleModel: 'XC40',
      vehicleColor: 'Black',
      plate: 'MVR 421',
    );
    expect(driver.firstName, 'Alex');
    expect(driver.plate, 'MVR 421');
    expect(driver.vehicleLabel, 'Black Volvo XC40');
    expect(driver.ratingLabel, '4.92');
    expect(driver.tripsLabel, '1284 trips');
    expect(driver.yearsOnMovera, isNull);
    expect(driver.languages, isEmpty);
  });
}
