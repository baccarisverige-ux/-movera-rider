import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/finding_driver/presentation/ride_details_sheet.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/ride_booking/domain/route_stop.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const stops = [
    RouteStop(address: 'Hötorget 1, Stockholm', latitude: 59.33, longitude: 18.06),
    RouteStop(address: 'Odenplan 2, Stockholm', latitude: 59.34, longitude: 18.05),
  ];

  Future<void> pump(
    WidgetTester tester, {
    bool canEditPickup = true,
    bool canEditDestination = true,
    bool canAddStop = true,
    List<RouteStop> stops = stops,
    int maxStops = 3,
    required void Function(String event) log,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RideDetailsSheet(
              pickupAddress: 'Sergels torg 1, Stockholm',
              destinationAddress: 'Arlanda, Stockholm',
              stops: stops,
              rideType: 'Movera',
              price: 259,
              paymentMethod: 'Apple Pay',
              notes: RideNotes.empty,
              canEditPickup: canEditPickup,
              canEditDestination: canEditDestination,
              canAddStop: canAddStop,
              maxStops: maxStops,
              onEditPickup: () => log('pickup'),
              onEditDestination: () => log('destination'),
              onAddStop: () => log('add'),
              onRemoveStop: (i) => log('remove $i'),
              onCancelTrip: () => log('cancel'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the stops in order and lets each row change', (tester) async {
    final events = <String>[];
    await pump(tester, log: events.add);

    expect(find.byKey(const ValueKey('ride-details-pickup')), findsOneWidget);
    expect(find.byKey(const ValueKey('ride-details-stop-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('ride-details-stop-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('ride-details-destination')), findsOneWidget);
    expect(find.textContaining('Hötorget'), findsOneWidget);
    expect(find.textContaining('Odenplan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('ride-details-add-stop')));
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('ride-details-stop-1')),
        matching: find.text('Remove'),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('ride-details-destination')),
        matching: find.text('Change'),
      ),
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('ride-details-pickup')),
        matching: find.text('Change'),
      ),
    );
    expect(events, ['add', 'remove 1', 'destination', 'pickup']);
  });

  testWidgets('once the driver is there only the route after the pickup changes',
      (tester) async {
    await pump(tester, canEditPickup: false, log: (_) {});
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ride-details-pickup')),
        matching: find.text('Change'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ride-details-destination')),
        matching: find.text('Change'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Your driver is told'), findsOneWidget);
  });

  testWidgets('no Add stop once the route has the most stops', (tester) async {
    await pump(tester, maxStops: 2, log: (_) {});
    expect(find.byKey(const ValueKey('ride-details-add-stop')), findsNothing);
  });
}
