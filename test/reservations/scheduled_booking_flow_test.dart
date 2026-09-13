import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/history/presentation/ride_history.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';
import 'package:movera_rider/features/reservations/presentation/ride_scheduled.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/features/ride_selection/application/scheduled_ride_booking.dart';
import 'package:movera_rider/features/ride_selection/domain/booking_mode.dart';
import 'package:movera_rider/features/ride_selection/presentation/scheduled_pickup_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    FindingDriverController.active = null;
    AppScope.instance.ride
      ..rideId = null
      ..status = RideStatus.idle;
  });

  ReservationController reservations({String Function()? nextId}) {
    var n = 0;
    return ReservationController(
      store: LocalReservationRepository(
        storage: MemoryReservationStorage(),
        nextId: nextId ?? () => 'rsv_${++n}',
      ),
    );
  }

  RideSelectionController scheduledSelection({
    String rideId = 'movera',
    DateTime? when,
  }) {
    final selection = RideSelectionController(
      bookingMode: BookingMode.scheduled,
    );
    final ride = selection.rideById(rideId);
    selection.selectRide(ride.id, ride.price);
    selection.scheduleFor(when ?? DateTime(2026, 9, 23, 6, 55));
    return selection;
  }

  Future<void> pumpPhone(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pump();
  }

  test('now mode still shows Select [category] and enters Finding Driver', () {
    final selection = RideSelectionController(bookingMode: BookingMode.now);
    expect(selection.bookingMode.ctaLabel('Movera'), 'Select Movera');
    expect(
      ScheduledRideBooking.ctaLabel(BookingMode.now, 'Movera'),
      'Select Movera',
    );
    expect(selection.entersFindingDriver, isTrue);
    expect(selection.createsReservation, isFalse);
  });

  test('scheduled date/time turns Select Movera into Schedule Movera', () {
    final selection = RideSelectionController();
    expect(selection.bookingMode.ctaLabel('Movera'), 'Select Movera');
    expect(selection.entersFindingDriver, isTrue);
    final catalog = selection.rides().map((ride) => ride.id).toList();
    selection.scheduleFor(DateTime(2026, 9, 23, 6, 55));
    expect(selection.bookingMode, BookingMode.scheduled);
    expect(selection.bookingMode.ctaLabel('Movera'), 'Schedule Movera');
    expect(
      ScheduledRideBooking.ctaLabel(selection.bookingMode, 'Movera'),
      'Schedule Movera',
    );
    expect(selection.entersFindingDriver, isFalse);
    expect(selection.createsReservation, isTrue);
    expect(selection.rides().map((ride) => ride.id), catalog);
    expect(selection.selectedRideId, 'movera');
  });

  test(
    'now-mode confirm refuses to create a reservation or start a search',
    () {
      final selection = RideSelectionController(bookingMode: BookingMode.now);
      final c = reservations();
      expect(
        () => ScheduledRideBooking.confirm(
          reservations: c,
          selection: selection,
          pickup: const ReservationPlace(label: 'Klockarvägen 37'),
          destination: const ReservationPlace(label: 'Arlanda Express'),
        ),
        throwsA(isA<StateError>()),
      );
      expect(c.all, isEmpty);
      expect(FindingDriverController.active, isNull);
      expect(AppScope.instance.ride.status, RideStatus.idle);
    },
  );

  test(
    'Schedule Movera creates exactly one reservation and never finds a driver',
    () async {
      final c = reservations();
      final selection = scheduledSelection();
      expect(selection.bookingMode.ctaLabel('Movera'), 'Schedule Movera');
      final created = await ScheduledRideBooking.confirm(
        reservations: c,
        selection: selection,
        pickup: const ReservationPlace(
          label: 'Klockarvägen 37',
          lat: 59.19,
          lng: 17.62,
        ),
        destination: const ReservationPlace(
          label: 'Arlanda Express',
          lat: 59.65,
          lng: 17.93,
        ),
      );
      expect(c.all, hasLength(1));
      expect(created.reservationId, 'rsv_1');
      expect(created.categoryName, 'Movera');
      expect(created.status, ReservationStatus.scheduled);
      expect(FindingDriverController.active, isNull);
      expect(AppScope.instance.ride.status, RideStatus.idle);
      expect(AppScope.instance.ride.rideId, isNull);
    },
  );

  testWidgets(
    'tapping Schedule Movera opens Ride scheduled, not Finding Driver',
    (tester) async {
      final c = reservations();
      final selection = scheduledSelection();
      await pumpPhone(
        tester,
        Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    final created = await ScheduledRideBooking.confirm(
                      reservations: c,
                      selection: selection,
                      pickup: const ReservationPlace(label: 'Klockarvägen 37'),
                      destination: const ReservationPlace(
                        label: 'Arlanda Express',
                      ),
                    );
                    if (!context.mounted) return;
                    await RideScheduledPage.open(
                      context,
                      reservationId: created.reservationId,
                      controller: c,
                    );
                  },
                  child: Text(selection.bookingMode.ctaLabel('Movera')),
                ),
              ),
            );
          },
        ),
      );
      expect(find.text('Select Movera'), findsNothing);
      expect(find.text('Schedule Movera'), findsOneWidget);
      await tester.tap(find.text('Schedule Movera'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      expect(c.all, hasLength(1));
      expect(c.all.single.reservationId, 'rsv_1');
      expect(find.text('Ride scheduled'), findsOneWidget);
      expect(find.text('Finding your driver later'), findsOneWidget);
      expect(find.text('Connecting you with nearby drivers'), findsNothing);
      expect(FindingDriverController.active, isNull);
      expect(AppScope.instance.ride.status, RideStatus.idle);
    },
  );

  testWidgets('real date and time pickers feed scheduled mode', (tester) async {
    DateTime? picked;
    await pumpPhone(
      tester,
      Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () async {
                picked = await chooseScheduledPickup(context);
              },
              child: const Text('pick'),
            ),
          );
        },
      ),
    );
    await tester.tap(find.text('pick'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Choose ride date'), findsOneWidget);
    await tester.tap(find.text('OK').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Choose pickup time'), findsOneWidget);
    await tester.tap(find.text('OK').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(picked, isNotNull);
    expect(
      picked!.isAfter(DateTime.now().subtract(const Duration(minutes: 1))),
      isTrue,
    );

    final selection = RideSelectionController();
    expect(selection.bookingMode.ctaLabel('Movera'), 'Select Movera');
    selection.scheduleFor(picked);
    expect(selection.bookingMode.ctaLabel('Movera'), 'Schedule Movera');
    expect(selection.entersFindingDriver, isFalse);
  });

  testWidgets('Ride scheduled appears under Upcoming with the same id', (
    tester,
  ) async {
    final store = MemoryReservationStorage();
    final c = ReservationController(
      store: LocalReservationRepository(
        storage: store,
        nextId: () => 'rsv_keep',
      ),
    );
    final created = await ScheduledRideBooking.confirm(
      reservations: c,
      selection: scheduledSelection(),
      pickup: const ReservationPlace(label: 'Klockarvägen 37'),
      destination: const ReservationPlace(label: 'Arlanda Express'),
    );
    await pumpPhone(
      tester,
      RideScheduledPage(reservationId: created.reservationId, controller: c),
    );
    expect(find.text('Ride scheduled'), findsOneWidget);
    expect(c.upcoming().single.reservationId, 'rsv_keep');

    await pumpPhone(tester, RideHistory(reservations: c));
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Klockarvägen 37 → Arlanda Express'), findsOneWidget);
    expect(c.all, hasLength(1));

    await c.update(
      'rsv_keep',
      ReservationPatch(
        scheduledPickupAt: DateTime(2026, 9, 24, 8, 15),
        pickup: const ReservationPlace(label: 'T-Centralen'),
        destination: const ReservationPlace(label: 'Arlanda Terminal 5'),
        paymentMethod: 'Swish',
      ),
    );
    await tester.pump();
    expect(c.all, hasLength(1));
    expect(c.byId('rsv_keep')!.reservationId, 'rsv_keep');
    expect(c.byId('rsv_keep')!.pickup.label, 'T-Centralen');
    expect(c.byId('rsv_keep')!.destination.label, 'Arlanda Terminal 5');
    expect(c.byId('rsv_keep')!.paymentMethod, 'Swish');
    expect(c.byId('rsv_keep')!.scheduledPickupAt, DateTime(2026, 9, 24, 8, 15));

    final restored = ReservationController(
      store: LocalReservationRepository(storage: store),
    );
    await restored.hydrate();
    expect(restored.all, hasLength(1));
    expect(restored.all.single.reservationId, 'rsv_keep');
    expect(restored.all.single.paymentMethod, 'Swish');

    await c.cancel('rsv_keep', reason: 'plans_changed');
    await tester.pump();
    expect(c.upcoming(), isEmpty);
    expect(c.cancelled().single.reservationId, 'rsv_keep');
    expect(c.all, hasLength(1));
  });

  test(
    'plan return ride uses the same category cards and waits for confirm',
    () async {
      final c = reservations();
      final origin = await ScheduledRideBooking.confirm(
        reservations: c,
        selection: scheduledSelection(),
        pickup: const ReservationPlace(
          label: 'Klockarvägen 37',
          lat: 59.19,
          lng: 17.62,
        ),
        destination: const ReservationPlace(
          label: 'Arlanda Express',
          lat: 59.65,
          lng: 17.93,
        ),
      );
      expect(c.all, hasLength(1));

      final returnSelection = RideSelectionController(
        bookingMode: BookingMode.scheduled,
        lockBookingMode: true,
      );
      returnSelection.scheduleFor(
        origin.scheduledPickupAt.add(const Duration(hours: 3)),
      );
      returnSelection.selectRide('comfort', 339);
      expect(
        returnSelection.bookingMode.ctaLabel('Comfort'),
        'Schedule Comfort',
      );
      expect(returnSelection.entersFindingDriver, isFalse);
      expect(
        c.all,
        hasLength(1),
        reason: 'return ride must not exist before confirm',
      );

      final ret = await ScheduledRideBooking.confirm(
        reservations: c,
        selection: returnSelection,
        pickup: ReservationPlace(label: origin.destination.label),
        destination: ReservationPlace(label: origin.pickup.label),
        parentReservationId: origin.reservationId,
      );
      expect(c.all, hasLength(2));
      expect(ret.reservationId, isNot(origin.reservationId));
      expect(ret.categoryId, 'comfort');
      expect(ret.pickup.label, 'Arlanda Express');
      expect(ret.destination.label, 'Klockarvägen 37');
      expect(ret.parentReservationId, origin.reservationId);
      expect(FindingDriverController.active, isNull);
      expect(AppScope.instance.ride.status, RideStatus.idle);
    },
  );
}
