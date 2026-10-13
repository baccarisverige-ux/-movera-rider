import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/features/pickup/presentation/set_pickup_page.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/saved_places/domain/saved_place.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<SetPickupResult?> Function() openPage(
    WidgetTester tester, {
    SetPickupFare fare = const SetPickupFare(totalKr: 237),
    bool fallback = false,
  }) {
    SetPickupResult? result;
    var done = false;
    return () async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await SetPickupPage.open(
                    context,
                    initialPosition: const LatLng(59.3293, 18.0686),
                    initialAddress: 'Klockarvägen 37',
                    destinationAddress: 'Alby Centrum, Norsborg',
                    destinationPosition: const LatLng(59.2390, 17.8450),
                    ride: const SetPickupRide(
                      name: 'Comfort',
                      image: 'missing.png',
                      seats: 4,
                      etaMin: 11,
                      tripMinutes: 22,
                    ),
                    fare: fare,
                    payment: const SetPickupPayment(
                      brand: 'cash',
                      name: 'Pay in car',
                      detail: 'Cash, card or Swish to the driver',
                    ),
                    brandMark: (_) => const Icon(Icons.directions_car),
                    onChangePayment: () async => null,
                    spots: const [
                      PlaceShortcut(title: 'Home', subtitle: 'Odenplan', kind: 'home'),
                    ],
                    positionIsFallback: fallback,
                  );
                  done = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      return done ? result : null;
    };
  }

  testWidgets('shows the ride, pickup, spots, bags, price, payment and CTA', (
    tester,
  ) async {
    await openPage(
      tester,
      fare: const SetPickupFare(totalKr: 237, discountKr: 102, promotionPercent: 30),
    )();
    expect(find.byType(SetPickupPage), findsOneWidget);
    expect(find.text('Alby Centrum, Norsborg'), findsOneWidget);
    expect(find.text('Comfort'), findsOneWidget);
    expect(find.textContaining('Driver arrives in 11 min'), findsOneWidget);
    expect(find.text('Pickup spot'), findsOneWidget);
    expect(find.text('Klockarvägen 37'), findsOneWidget);
    expect(find.text('Your current location'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('On map'), findsOneWidget);
    expect(find.text('Bags?'), findsOneWidget);
    expect(find.text('Ride price'), findsOneWidget);
    expect(find.text('kr 339'), findsOneWidget);
    expect(find.text('Promotion 30%'), findsOneWidget);
    expect(find.text('-kr 102'), findsOneWidget);
    expect(find.text('kr 237'), findsOneWidget);
    expect(find.text('Pay in car'), findsOneWidget);
    expect(find.text('Confirm and search'), findsOneWidget);
    expect(find.byKey(const ValueKey('set-pickup-pin')), findsOneWidget);
  });

  testWidgets('without a promotion only the total is shown', (tester) async {
    await openPage(tester)();
    expect(find.text('Ride price'), findsNothing);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('kr 237'), findsOneWidget);
  });

  testWidgets('confirm returns the pickup and the chosen bags', (tester) async {
    SetPickupResult? result;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await SetPickupPage.open(
                  context,
                  initialPosition: const LatLng(59.3293, 18.0686),
                  initialAddress: 'Klockarvägen 37',
                  destinationAddress: 'Odenplan',
                  destinationPosition: const LatLng(59.3429, 18.0496),
                  ride: const SetPickupRide(
                    name: 'Comfort',
                    image: 'missing.png',
                    seats: 4,
                    etaMin: 6,
                    tripMinutes: 12,
                  ),
                  fare: const SetPickupFare(totalKr: 199),
                  payment: const SetPickupPayment(
                    brand: 'cash',
                    name: 'Pay in car',
                    detail: '',
                  ),
                  brandMark: (_) => const SizedBox(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Opens short: the bags sit in the details, one tap on the handle away.
    await tester.tap(find.byKey(const ValueKey('set-pickup-handle')));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('3+'));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('Confirm and search'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(SetPickupPage), findsNothing);
    expect(result, isNotNull);
    expect(result!.address, 'Klockarvägen 37');
    expect(result!.bagLevel, 2);
    expect(result!.position, const LatLng(59.3293, 18.0686));
  });

  testWidgets('a fallback map point cannot be confirmed', (tester) async {
    await openPage(tester, fallback: true)();
    final button = tester.widget<FilledButton>(
      find.byKey(const ValueKey('set-pickup-confirm')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('opens short; the handle shows the details and hides them', (
    tester,
  ) async {
    await openPage(tester)();
    expect(find.text('Bags?').hitTestable(), findsNothing);
    expect(find.text('Confirm and search').hitTestable(), findsOneWidget);
    expect(find.text('Klockarvägen 37').hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('set-pickup-handle')));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Bags?').hitTestable(), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('set-pickup-handle')));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Bags?').hitTestable(), findsNothing);
  });

  testWidgets('dragging the sheet up brings the details in', (tester) async {
    await openPage(tester)();
    await tester.drag(find.text('Pickup spot'), const Offset(0, -320));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Bags?').hitTestable(), findsOneWidget);
  });

  test('bags are kept on the ride notes', () {
    final notes = RideNotes.empty.withBagLevel(2);
    expect(notes.bagLevel, 2);
    expect(notes.toJson()['bagsCount'], '3+');
    expect(RideNotes.fromJson(notes.toJson()).bagLevel, 2);
    expect(RideNotes.empty.withBagLevel(1).selected, ['Bags']);
    expect(RideNotes.empty.withBagLevel(0).bags, isFalse);
  });
}
