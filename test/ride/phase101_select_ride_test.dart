import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/features/ride_selection/presentation/select_ride.dart';
import 'package:movera_rider/features/ride_selection/presentation/select_ride_geometry.dart';

class _ImmediateQuotes implements QuoteRepository {
  @override
  Future<RideQuote> quote({
    required String rideType,
    required int distanceMeters,
    int durationSeconds = 600,
    String? pickup,
    String? destination,
  }) => Future<RideQuote>.value(
    RideQuote(
      id: 'q-$rideType',
      rideType: rideType,
      totalMinor: 25900,
      currency: 'SEK',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      signedPayload: 'sig',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> openSelectRide(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final selection = RideSelectionController(quotes: _ImmediateQuotes());
    addTearDown(selection.dispose);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: nav, home: const Scaffold(body: Text('home'))),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.selectRide),
        builder: (_) => SelectRide(
          pickupAddress: 'Stockholm Central',
          destinationAddress: 'Odenplan',
          pickupPosition: const LatLng(59.3293, 18.0686),
          destinationPosition: const LatLng(59.3429, 18.0496),
          pickupAlreadyConfirmed: true,
          selection: selection,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  testWidgets('D-006: no price stepper that can only dead-end', (tester) async {
    await openSelectRide(tester);
    final inSelectRide = find.descendant(
      of: find.byType(SelectRide),
      matching: find.byWidgetPredicate(
        (w) =>
            w is Icon &&
            (w.icon == Icons.remove_rounded || w.icon == Icons.add_rounded),
      ),
    );
    expect(inSelectRide, findsNothing);
  });

  test('D-007: the map uses the confirmed pickup, not the constructor one', () {
    final src = File(
      'lib/features/ride_selection/presentation/select_ride.dart',
    ).readAsStringSync();
    // The only read of widget.pickupPosition is seeding _pickupPosition in
    // initState; markers, route, initial camera and fitBounds must all follow
    // _pickupPosition so a re-confirmed pickup is what the rider sees.
    expect(
      RegExp(r'widget\.pickupPosition').allMatches(src).length,
      1,
    );
    expect(src, contains('_pickupPosition = widget.pickupPosition;'));
  });

  group('D-009: the map is visible above the ride sheet', () {
    test('the expanded sheet leaves at least a third of the screen', () {
      const media = MediaQueryData(size: Size(390, 844));
      final maxSheet = selectRideMaxSheetHeight(media);
      expect(844 - maxSheet, greaterThanOrEqualTo(844 * 0.33));
    });

    test('large text still gets the full height it needs', () {
      const media = MediaQueryData(
        size: Size(390, 844),
        textScaler: TextScaler.linear(2),
      );
      expect(selectRideMaxSheetHeight(media), 844);
    });

    test('both pins are framed in the part of the map the sheet leaves', () {
      const pickup = GeoPoint(59.3293, 18.0686);
      const destination = GeoPoint(59.3429, 18.0496);
      final fit = selectRideCameraFit(
        pickup: pickup,
        destination: destination,
        mapHeight: 496,
        bottomObstruction: 210,
      );
      expect(fit.northeast.latitude, destination.latitude);
      expect(fit.northeast.longitude, pickup.longitude);
      expect(fit.southwest.longitude, destination.longitude);
      // Only the south edge is stretched, by the covered share of the map.
      final span = destination.latitude - pickup.latitude;
      final full = 496 - 2 * fit.padding;
      final usable = 496 - 210 - 2 * fit.padding;
      expect(
        fit.southwest.latitude,
        closeTo(destination.latitude - span * full / usable, 1e-9),
      );
    });
  });
}
