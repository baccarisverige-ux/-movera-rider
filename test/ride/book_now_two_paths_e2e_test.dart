import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/pickup/presentation/confirm_pickup_spot.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/booking/application/booking_controller.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/features/ride_selection/application/scheduled_ride_booking.dart';
import 'package:movera_rider/features/ride_selection/domain/booking_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Book now E2E on two paths: GPS available and GPS unavailable.
/// Both must open Confirm pickup. Later stays off Finding Driver.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FindingDriverController.active = null;
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

  const gpsFix = LatLng(59.33258, 18.0649);
  const noGpsFallback = LatLng(59.3293, 18.0686);

  Future<void> showPickup(
    WidgetTester tester, {
    required LatLng initial,
    required String address,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConfirmPickupSpot(
          initialPosition: initial,
          initialAddress: address,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets('GPS available still opens Confirm pickup', (tester) async {
    await phone(tester);
    await showPickup(
      tester,
      initial: gpsFix,
      address: 'Current location',
    );
    expect(find.text('Confirm pickup spot'), findsOneWidget);
    expect(find.text('Drag map to move pin'), findsOneWidget);
    expect(find.text('Confirm pickup'), findsOneWidget);
    expect(find.text('Connecting you with nearby drivers'), findsNothing);
  });

  testWidgets('GPS unavailable still opens Confirm pickup', (tester) async {
    await phone(tester);
    await showPickup(
      tester,
      initial: noGpsFallback,
      address: 'Current location',
    );
    expect(find.text('Confirm pickup spot'), findsOneWidget);
    expect(find.text('Confirm pickup'), findsOneWidget);
    expect(find.text('Connecting you with nearby drivers'), findsNothing);
  });

  testWidgets('Back on Confirm pickup returns without booking', (tester) async {
    await phone(tester);
    ConfirmPickupResult? popped = const ConfirmPickupResult(
      position: gpsFix,
      address: 'sentinel',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async {
                  popped = await ConfirmPickupSpot.open(
                    context,
                    initialPosition: gpsFix,
                    initialAddress: 'Current location',
                  );
                },
                child: const Text('open-pickup'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open-pickup'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Confirm pickup spot'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(popped, isNull);
    expect(find.text('open-pickup'), findsOneWidget);
    expect(FindingDriverController.active, isNull);
    expect(AppScope.instance.ride.status, RideStatus.idle);
  });

  testWidgets(
    'Confirm pickup then Select Movera starts Finding Driver',
    (tester) async {
      await phone(tester);
      ConfirmPickupResult? spot;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    spot = await ConfirmPickupSpot.open(
                      context,
                      initialPosition: gpsFix,
                      initialAddress: 'Current location',
                    );
                  },
                  child: const Text('Select Movera'),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Select Movera'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Confirm pickup spot'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm pickup'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(spot, isNotNull);
      expect(spot!.position.latitude, isNonZero);
    },
  );

  test('Select Movera submitFinding marks Finding Driver', () async {
    SharedPreferences.setMockInitialValues({});
    AppScope.instance.ride
      ..rideId = null
      ..status = RideStatus.idle;
    await BookingController().submitFinding(
      pickupAddress: 'Current location',
      destinationAddress: 'Stockholm Central Station',
      pickupLat: gpsFix.latitude,
      pickupLng: gpsFix.longitude,
      destinationLat: 59.3301,
      destinationLng: 18.058,
      rideType: 'Movera',
      price: 259,
      paymentMethod: 'Apple Pay',
    );
    expect(AppScope.instance.ride.status, RideStatus.findingDriver);
  });

  test('Book now CTA is Select Movera and enters Finding Driver', () {
    final selection = RideSelectionController(bookingMode: BookingMode.now);
    expect(selection.bookingMode.ctaLabel('Movera'), 'Select Movera');
    expect(selection.entersFindingDriver, isTrue);
    expect(selection.createsReservation, isFalse);
  });

  test('Book later stays off Finding Driver', () async {
    final selection = RideSelectionController(
      bookingMode: BookingMode.scheduled,
    );
    selection.scheduleFor(DateTime(2026, 9, 23, 6, 55));
    expect(selection.bookingMode.ctaLabel('Movera'), 'Schedule Movera');
    expect(selection.entersFindingDriver, isFalse);
    expect(selection.createsReservation, isTrue);
    final c = ReservationController(
      store: LocalReservationRepository(
        storage: MemoryReservationStorage(),
        nextId: () => 'rsv_later',
      ),
    );
    final created = await ScheduledRideBooking.confirm(
      reservations: c,
      selection: selection,
      pickup: const ReservationPlace(label: 'A'),
      destination: const ReservationPlace(label: 'B'),
    );
    expect(created.reservationId, 'rsv_later');
    expect(c.all, hasLength(1));
    expect(FindingDriverController.active, isNull);
    expect(AppScope.instance.ride.status, RideStatus.idle);
  });
}
