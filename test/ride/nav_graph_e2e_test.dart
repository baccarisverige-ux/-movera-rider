import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/app/router/ride_navigator.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/history/presentation/ride_history.dart';
import 'package:movera_rider/features/pickup/presentation/confirm_pickup_spot.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/features/ride_selection/application/scheduled_ride_booking.dart';
import 'package:movera_rider/features/ride_selection/domain/booking_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locks rider navigation-graph contracts: book now vs later, return id,
/// History tabs, cancel pop, RideCompleted Done, and documented gaps.
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

  ReservationController seeded({String Function()? nextId}) {
    var n = 0;
    return ReservationController(
      store: LocalReservationRepository(
        storage: MemoryReservationStorage(),
        nextId: nextId ?? () => 'rsv_${++n}',
      ),
    );
  }

  Future<Reservation> createSample(ReservationController c) {
    return c.create(
      ReservationDraft(
        scheduledPickupAt: DateTime(2026, 9, 23, 6, 55),
        estimatedDropoffAt: DateTime(2026, 9, 23, 7, 26),
        pickup: const ReservationPlace(
          label: 'Klockarvägen 37',
          subtitle: 'Södertälje',
        ),
        destination: const ReservationPlace(
          label: 'Arlanda Express',
          subtitle: 'Stockholm',
        ),
        categoryId: 'movera',
        categoryName: 'Movera',
        categoryImage: 'assets/images/rides/movera.png',
        price: 522,
        paymentMethod: 'Cash',
        note: 'Bags · Pet',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // A) RideCompleted Done → RideNavigator.home
  // ---------------------------------------------------------------------------

  test('RideCompleted Done calls RideNavigator.home (not empty onPressed)', () {
    final src = File(
      'lib/features/ride_complete/presentation/ride_completed.dart',
    ).readAsStringSync();
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

  // ---------------------------------------------------------------------------
  // B) Upcoming cancel pops back to History
  // ---------------------------------------------------------------------------

  test('upcoming cancel source pops after successful cancel', () {
    final src = File(
      'lib/features/reservations/presentation/upcoming_reservation.dart',
    ).readAsStringSync();
    final cancelStart = src.indexOf('Future<void> _cancel');
    expect(cancelStart, greaterThan(0));
    final cancelEnd = src.indexOf('Future<void> _planReturn', cancelStart);
    final cancel = src.substring(cancelStart, cancelEnd);
    expect(cancel.contains('_reservations.cancel'), isTrue);
    expect(cancel.contains('Navigator.pop(context)'), isTrue);
  });

  testWidgets('upcoming reservation cancel pops back to History', (
    tester,
  ) async {
    await phone(tester);
    final c = seeded();
    await createSample(c);
    await tester.pumpWidget(
      MaterialApp(
        home: RideHistory(reservations: c),
      ),
    );
    await tester.pump();
    expect(find.text('Rides'), findsOneWidget);
    expect(find.text('Klockarvägen 37 → Arlanda Express'), findsOneWidget);

    await tester.tap(find.text('Klockarvägen 37 → Arlanda Express'));
    await tester.pumpAndSettle();
    expect(find.text('Upcoming ride'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Cancel reservation'), 400);
    await tester.tap(find.text('Cancel reservation').first);
    await tester.pumpAndSettle();
    expect(find.text('Cancel reservation?'), findsOneWidget);

    // Confirm on the sheet (same label as the page button).
    await tester.tap(find.widgetWithText(TextButton, 'Cancel reservation').last);
    await tester.pumpAndSettle();
    expect(find.text('Why are you cancelling?'), findsOneWidget);

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect(find.text('Upcoming ride'), findsNothing);
    expect(find.text('Rides'), findsOneWidget);
    expect(c.cancelled().single.reservationId, 'rsv_1');
    expect(c.upcoming(), isEmpty);
  });

  // ---------------------------------------------------------------------------
  // C) Book now vs later separation, return id, History tabs
  // ---------------------------------------------------------------------------

  test('ScheduleRide / checkout / lockBookingMode never construct FindingDrivers',
      () {
    for (final path in [
      'lib/features/scheduled_rides/presentation/schedule_ride.dart',
      'lib/features/reservations/application/scheduled_ride_checkout.dart',
      'lib/features/reservations/presentation/scheduled_category_gate.dart',
      'lib/features/reservations/presentation/plan_return_ride.dart',
    ]) {
      final src = File(path).readAsStringSync();
      expect(src.contains('FindingDrivers'), isFalse, reason: path);
      expect(src.contains('submitFinding'), isFalse, reason: path);
    }
    final gate = File(
      'lib/features/reservations/presentation/scheduled_category_gate.dart',
    ).readAsStringSync();
    expect(gate.contains('lockBookingMode: true'), isTrue);
    expect(gate.contains('bookingMode: BookingMode.scheduled'), isTrue);

    final checkout = File(
      'lib/features/reservations/application/scheduled_ride_checkout.dart',
    ).readAsStringSync();
    expect(
      checkout.contains('scheduled checkout cannot enter Finding Driver'),
      isTrue,
    );
  });

  test('locked scheduled selection never enters Finding Driver', () {
    final selection = RideSelectionController(
      bookingMode: BookingMode.scheduled,
      lockBookingMode: true,
    );
    selection.scheduleFor(DateTime(2026, 9, 23, 18, 0));
    selection.setBookingMode(BookingMode.now);
    expect(selection.bookingMode, BookingMode.scheduled);
    expect(selection.entersFindingDriver, isFalse);
    expect(selection.createsReservation, isTrue);
  });

  test('scheduled booking refuses now-mode Finding Driver path', () {
    final selection = RideSelectionController(bookingMode: BookingMode.now);
    final c = seeded();
    expect(
      () => ScheduledRideBooking.confirm(
        reservations: c,
        selection: selection,
        pickup: const ReservationPlace(label: 'A'),
        destination: const ReservationPlace(label: 'B'),
      ),
      throwsA(isA<StateError>()),
    );
    expect(c.all, isEmpty);
    expect(FindingDriverController.active, isNull);
  });

  test('Book later confirm never starts Finding Driver', () async {
    final selection = RideSelectionController(
      bookingMode: BookingMode.scheduled,
    );
    selection.scheduleFor(DateTime(2026, 9, 23, 6, 55));
    final c = seeded();
    final created = await ScheduledRideBooking.confirm(
      reservations: c,
      selection: selection,
      pickup: const ReservationPlace(label: 'A'),
      destination: const ReservationPlace(label: 'B'),
    );
    expect(created.reservationId, 'rsv_1');
    expect(FindingDriverController.active, isNull);
    expect(AppScope.instance.ride.status, RideStatus.idle);
  });

  test('plan return creates NEW reservationId with parentReservationId',
      () async {
    final c = seeded();
    final origin = await createSample(c);
    final ret = await c.planReturn(
      origin,
      scheduledPickupAt: DateTime(2026, 9, 24, 18, 30),
    );
    expect(ret.reservationId, isNot(origin.reservationId));
    expect(ret.parentReservationId, origin.reservationId);
    expect(ret.pickup.label, origin.destination.label);
    expect(ret.destination.label, origin.pickup.label);
    expect(c.all, hasLength(2));
    expect(FindingDriverController.active, isNull);
  });

  test('ScheduledRideBooking return path sets parentReservationId', () async {
    final c = seeded();
    final origin = await createSample(c);
    final selection = RideSelectionController(
      bookingMode: BookingMode.scheduled,
      lockBookingMode: true,
    );
    selection.scheduleFor(DateTime(2026, 9, 24, 18, 30));
    final ret = await ScheduledRideBooking.confirm(
      reservations: c,
      selection: selection,
      pickup: ReservationPlace(label: origin.destination.label),
      destination: ReservationPlace(label: origin.pickup.label),
      parentReservationId: origin.reservationId,
    );
    expect(ret.reservationId, isNot(origin.reservationId));
    expect(ret.parentReservationId, origin.reservationId);
    expect(c.all, hasLength(2));
  });

  testWidgets('History exposes Upcoming Completed Cancelled tabs', (
    tester,
  ) async {
    await phone(tester);
    final c = seeded();
    await createSample(c);
    await tester.pumpWidget(MaterialApp(home: RideHistory(reservations: c)));
    await tester.pump();
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('Rides'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Confirm pickup Back stays off booking (architecture + light widget)
  // ---------------------------------------------------------------------------

  testWidgets('Confirm pickup Back returns without booking', (tester) async {
    await phone(tester);
    const gpsFix = LatLng(59.33258, 18.0649);
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
  });

  // ---------------------------------------------------------------------------
  // Rebook: control exists; current behavior is Navigator.pop only (documented)
  // ---------------------------------------------------------------------------

  testWidgets('History Rebook control is visible on Completed', (tester) async {
    await phone(tester);
    final c = seeded();
    await tester.pumpWidget(MaterialApp(home: RideHistory(reservations: c)));
    await tester.pump();
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Rebook'), findsWidgets);
  });

  test(
    // CURRENT product: _rebookChip onTap is Navigator.pop(context) only.
    // No intended rebook destination method found — left product unchanged.
    'History Rebook source still pops History (documented gap, no product change)',
    () {
      final src = File(
        'lib/features/history/presentation/ride_history.dart',
      ).readAsStringSync();
      expect(src.contains("'Rebook'"), isTrue);
      final chipStart = src.indexOf('Widget _rebookChip');
      expect(chipStart, greaterThan(0));
      final chip = src.substring(chipStart, src.indexOf('class _MiniRoutePainter'));
      expect(chip.contains('Navigator.pop(context)'), isTrue);
      expect(chip.contains('ScheduleRide'), isFalse);
      expect(chip.contains('SelectRide'), isFalse);
      expect(chip.contains('FindingDrivers'), isFalse);
    },
  );

  // ---------------------------------------------------------------------------
  // Become a driver / AppRoutes — architecture comments only
  // ---------------------------------------------------------------------------

  test(
    // Become a driver card has no onTap; AppRoutes remain the named contract
    // while screens still push with transitions (unused route names OK).
    'Become a driver is present without route wiring; AppRoutes stay named contract',
    () {
      final menu = File(
        'lib/features/home/presentation/side_menu.dart',
      ).readAsStringSync();
      expect(menu.contains('Become a driver'), isTrue);
      final becomeStart = menu.indexOf('Widget _becomeDriverCard');
      final becomeEnd = menu.indexOf('Widget _footer');
      expect(becomeStart, greaterThan(0));
      final become = menu.substring(becomeStart, becomeEnd);
      expect(become.contains('Navigator'), isFalse);
      expect(become.contains('onTap'), isFalse);

      final routes = File('lib/app/router/routes.dart').readAsStringSync();
      expect(routes.contains("static const home = '/'"), isTrue);
      expect(routes.contains('rideHistory'), isTrue);
      expect(routes.contains('findingDriver'), isTrue);
      expect(routes.contains('rideCompleted'), isTrue);
    },
  );

  // ---------------------------------------------------------------------------
  // Safety Kit gap (skip product change)
  // ---------------------------------------------------------------------------

  test(
    // GAP: RideSafetyKitSheet._openHub pops the kit before pushing SafetyHub.
    // Preferred product: push hub without popping kit first so back returns
    // to the kit. Large rewrite skipped — documenting only.
    'Safety Kit still pops before opening hub (documented gap)',
    () {
      final src = File(
        'lib/features/safety/presentation/ride_safety_kit.dart',
      ).readAsStringSync();
      final openStart = src.indexOf('void _openHub()');
      expect(openStart, greaterThan(0));
      final open = src.substring(openStart, src.indexOf('@override', openStart));
      expect(open.contains('nav.pop()'), isTrue);
      expect(open.contains('SafetyHub'), isTrue);
    },
  );
}
