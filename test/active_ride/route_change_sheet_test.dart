import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/features/active_ride/application/route_change_controller.dart';
import 'package:movera_rider/features/active_ride/presentation/route_change_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  RouteChangeQuote quote({double newPrice = 369}) => RouteChangeQuote(
    pickupAddress: 'Sergels torg 1',
    pickupPoint: const GeoPoint(59.33, 18.06),
    destinationAddress: 'Arlanda',
    destinationPoint: const GeoPoint(59.65, 17.93),
    stops: const [],
    oldPriceKr: 259,
    newPriceKr: newPrice,
  );

  Future<bool?> pump(
    WidgetTester tester, {
    required String paymentMethod,
    double newPrice = 369,
    required Future<void> Function() act,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await RouteChangeSheet.confirm(
                    context,
                    quote: quote(newPrice: newPrice),
                    paymentMethod: paymentMethod,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await act();
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('Pay in car: the price is shown and one confirm is enough',
      (tester) async {
    final result = await pump(
      tester,
      paymentMethod: 'Pay in car',
      act: () async {
        expect(find.byKey(const ValueKey('route-change-price')), findsOneWidget);
        expect(find.text('369 kr'), findsOneWidget);
        expect(find.textContaining('in the car'), findsOneWidget);
        expect(find.text('Confirm change'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('route-change-confirm')));
      },
    );
    expect(result, isTrue);
  });

  testWidgets('Apple Pay: a payment step confirms the charge', (tester) async {
    final result = await pump(
      tester,
      paymentMethod: 'Apple Pay',
      act: () async {
        expect(find.textContaining('charged to Apple Pay'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('route-change-confirm')));
        await tester.pumpAndSettle();
        expect(find.text('Update payment'), findsOneWidget);
        expect(find.byKey(const ValueKey('route-change-payment')), findsOneWidget);
        expect(find.text('+110 kr'), findsOneWidget);
        expect(find.text('Confirm and pay 110 kr'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('route-change-pay')));
      },
    );
    expect(result, isTrue);
  });

  testWidgets('a cheaper route on a card confirms the refund', (tester) async {
    final result = await pump(
      tester,
      paymentMethod: 'Visa •••• 4242',
      newPrice: 130,
      act: () async {
        await tester.tap(find.byKey(const ValueKey('route-change-confirm')));
        await tester.pumpAndSettle();
        expect(find.text('Returned to you'), findsOneWidget);
        expect(find.text('−129 kr'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('route-change-pay')));
      },
    );
    expect(result, isTrue);
  });

  testWidgets('Keep current route resolves false', (tester) async {
    final result = await pump(
      tester,
      paymentMethod: 'Apple Pay',
      act: () async => tester.tap(find.text('Keep current route')),
    );
    expect(result, isFalse);
  });
}
