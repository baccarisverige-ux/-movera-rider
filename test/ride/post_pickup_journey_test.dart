import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/active_ride/presentation/rider_in_trip_panel.dart';
import 'package:movera_rider/features/finding_driver/presentation/ride_details_sheet.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('post-pickup panel is destination-first and keeps safety available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RiderInTripPanel(
            destinationAddress: 'Hornsgatan 2, Stockholm',
            rideType: 'Movera',
            paymentMethod: 'Apple Pay',
            price: 259,
            driver: null,
            rideId: 'ride-in-trip-1',
            onOpenProfile: _noop,
            onCall: _noop,
            onMore: _noop,
          ),
        ),
      ),
    );

    expect(find.text('ON TRIP'), findsOneWidget);
    expect(find.text('Ride in progress'), findsOneWidget);
    expect(find.text('Hornsgatan 2, Stockholm'), findsWidgets);
    expect(find.text('Destination'), findsOneWidget);
    expect(find.text('Safety Kit'), findsOneWidget);
    expect(find.text('Show this PIN to your driver'), findsNothing);
    expect(find.text('Cancel trip'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('approaching dropoff gets its own destination-first state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RiderInTripPanel(
            destinationAddress: 'Hornsgatan 2, Stockholm',
            rideType: 'Movera',
            paymentMethod: 'Apple Pay',
            price: 259,
            driver: null,
            rideId: 'ride-near-destination-1',
            status: RideStatus.approachingDropoff,
            onOpenProfile: _noop,
            onCall: _noop,
            onMore: _noop,
          ),
        ),
      ),
    );

    expect(find.text('NEAR DESTINATION'), findsOneWidget);
    expect(find.text('Approaching destination'), findsOneWidget);
    expect(find.text('Hornsgatan 2, Stockholm'), findsWidgets);
    expect(find.text('Meet at'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('trip details hide cancellation once pickup is complete', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RideDetailsSheet(
            pickupAddress: 'Sveavägen 1, Stockholm',
            destinationAddress: 'Hornsgatan 2, Stockholm',
            rideType: 'Movera',
            price: 259,
            paymentMethod: 'Apple Pay',
            notes: RideNotes.empty,
            canEditPickup: false,
            allowCancel: false,
            onEditPickup: _noop,
            onEditDestination: _noop,
            onCancelTrip: _noop,
          ),
        ),
      ),
    );

    expect(find.text('Ride details'), findsOneWidget);
    expect(find.text('Cancel trip'), findsNothing);
    expect(find.text('Close'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
