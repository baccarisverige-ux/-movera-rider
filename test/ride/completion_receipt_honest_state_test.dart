import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_booking/data/driver_repository.dart';
import 'package:movera_rider/features/ride_complete/application/ride_complete_controller.dart';
import 'package:movera_rider/features/ride_complete/presentation/trip_detail.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('completion receipt repository does not seed trip details', () {
    expect(const TripReceiptRepository().last(), isNull);
  });

  test('explicit receipt remains available unchanged', () {
    const receipt = TripReceipt(
      pickup: 'Real pickup',
      destination: 'Real destination',
      total: '245 kr',
      method: 'Apple Pay',
    );
    final stored = const TripReceiptRepository(last: receipt).last();

    expect(stored, same(receipt));
    expect(stored?.pickup, 'Real pickup');
    expect(stored?.total, '245 kr');
  });

  testWidgets('completion UI shows honest state when receipt is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => const MaterialApp(
          home: Scaffold(body: RideCompletedTripDetail()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip Details'), findsOneWidget);
    expect(find.text('Trip details unavailable'), findsOneWidget);
    expect(find.text('I11/Street 15 - h350'), findsNothing);
    expect(find.text('Skypulse solution'), findsNothing);
    expect(find.text(r'$10.12'), findsNothing);
    expect(find.text('Cash'), findsNothing);
  });

  testWidgets('completion UI renders an explicitly supplied real receipt', (
    tester,
  ) async {
    const receipt = TripReceipt(
      pickup: 'Real pickup',
      destination: 'Real destination',
      total: '245 kr',
      method: 'Apple Pay',
    );
    final controller = RideCompleteController(
      trips: const TripReceiptRepository(last: receipt),
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: RideCompletedTripDetail(controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Trip details unavailable'), findsNothing);
    expect(find.text('Real pickup'), findsOneWidget);
    expect(find.text('Real destination'), findsOneWidget);
    expect(find.text('245 kr'), findsOneWidget);
    expect(find.text('Apple Pay'), findsOneWidget);
  });
}
