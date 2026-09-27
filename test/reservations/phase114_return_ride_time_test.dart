import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/pickup/presentation/confirm_pickup_spot.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';
import 'package:movera_rider/features/reservations/presentation/plan_return_ride.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_selection/presentation/select_ride.dart';
import 'package:movera_rider/features/scheduled_rides/application/stockholm_schedule.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/select_date_time.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 114: "Plan a return ride" prefills pickup = origin + 3 h. That time
/// must pass the same StockholmSchedule rules as the main scheduling screen
/// (30-minute lead, 5-minute slots) before a reservation can be created. An
/// illegal prefill routes the rider through the shared validated picker.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    FindingDriverController.active = null;
    AppScope.instance.ride
      ..rideId = null
      ..status = RideStatus.idle;
  });

  ReservationController reservations() {
    var n = 0;
    return ReservationController(
      store: LocalReservationRepository(
        storage: MemoryReservationStorage(),
        nextId: () => 'rsv_return_${++n}',
      ),
    );
  }

  Reservation origin(DateTime pickupAt) {
    return Reservation(
      reservationId: 'rsv_origin',
      createdAt: pickupAt.subtract(const Duration(days: 1)),
      scheduledPickupAt: pickupAt,
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
      categoryId: 'movera',
      categoryName: 'Movera',
      categoryImage: 'assets/images/rides/movera.webp',
      price: 522,
      paymentMethod: 'Cash',
      status: ReservationStatus.scheduled,
    );
  }

  /// flutter_test defaults to Android, which routes the authenticated mock
  /// quote calls through the absent native secure-storage channel (see
  /// test/journeys/book_to_home_test.dart). Use a desktop platform like the
  /// journey tests do, and restore it inside the body so the binding's
  /// debug-variable invariant check passes.
  void phase114Widgets(
    String description,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(description, (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await body(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  Future<void> pumpApp(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp(
          navigatorKey: moveraNavigatorKey,
          home: const Scaffold(body: Center(child: Text('phase114-home'))),
        ),
      ),
    );
    moveraNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
  }

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 60 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tapSchedule(WidgetTester tester) async {
    final cta = find.text('Schedule Movera');
    await waitFor(tester, cta);
    expect(cta, findsOneWidget);
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pump();
  }

  /// Waits until either the validated picker or the pickup-spot screen is on
  /// top, i.e. the next step after tapping Schedule Movera.
  Future<void> waitForNextStep(WidgetTester tester) async {
    for (
      var i = 0;
      i < 60 &&
          find.byType(ScheduleDateTimeSelector).evaluate().isEmpty &&
          find.byType(ConfirmPickupSpot).evaluate().isEmpty;
      i++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> confirmPickupSpot(WidgetTester tester) async {
    await waitFor(tester, find.byType(ConfirmPickupSpot));
    expect(find.byType(ConfirmPickupSpot), findsOneWidget);
    final button = find.widgetWithText(FilledButton, 'Confirm pickup spot');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  Future<void> settleBooking(WidgetTester tester, List<String> opened) async {
    for (var i = 0; i < 60 && opened.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Let the booked popup auto-dismiss so no timers leak past the test.
    await tester.pump(const Duration(seconds: 5));
  }

  Future<void> expectPickerRepairsTime(
    WidgetTester tester, {
    required Duration originOffset,
  }) async {
    final c = reservations();
    final opened = <String>[];
    final ride = origin(StockholmSchedule.stockholmNow().add(originOffset));
    final prefill = ride.scheduledPickupAt.add(const Duration(hours: 3));
    expect(
      StockholmSchedule.isLegalPickup(prefill),
      isFalse,
      reason: 'precondition: origin + 3 h breaks the 30-minute lead rule',
    );
    await pumpApp(
      tester,
      PlanReturnRidePage(
        origin: ride,
        controller: c,
        onScheduled: (context, id) async => opened.add(id),
      ),
    );

    await tapSchedule(tester);
    await waitForNextStep(tester);

    expect(
      find.byType(ConfirmPickupSpot),
      findsNothing,
      reason: 'an illegal prefill must not skip straight to pickup confirm',
    );
    expect(
      find.byType(ScheduleDateTimeSelector),
      findsOneWidget,
      reason: 'an illegal return prefill must open the shared validated picker',
    );
    expect(c.all, isEmpty, reason: 'nothing may be booked before the picker');
    // The picker opens on the prefill clamped by the existing rules, i.e.
    // the next legal slot (the minute boundary may tick during the test).
    final slotBefore = StockholmSchedule.clampPickup(prefill);

    final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();
    await confirmPickupSpot(tester);
    await settleBooking(tester, opened);

    expect(c.all, hasLength(1));
    final booked = c.all.single;
    expect(opened, [booked.reservationId]);
    expect(booked.parentReservationId, 'rsv_origin');
    expect(booked.scheduledPickupAt, isNot(prefill));
    expect(
      booked.scheduledPickupAt,
      anyOf(slotBefore, StockholmSchedule.clampPickup(prefill)),
      reason: 'the picker default is the clamped prefill',
    );
    expect(
      StockholmSchedule.isLegalPickup(booked.scheduledPickupAt),
      isTrue,
      reason: 'the booked return pickup satisfies the 30-minute lead',
    );
    expect(booked.scheduledPickupAt.minute % StockholmSchedule.slotMinutes, 0);
  }

  phase114Widgets(
    'Phase 114 repro: return prefill in the past goes through the validated picker',
    (tester) async {
      // Origin 4 h ago -> prefill is 1 h in the past.
      await expectPickerRepairsTime(
        tester,
        originOffset: const Duration(hours: -4),
      );
    },
  );

  phase114Widgets(
    'Phase 114 repro: return prefill minutes away goes through the validated picker',
    (tester) async {
      // Origin 2 h 55 m ago -> prefill is about 5 minutes from now (< 30 min).
      await expectPickerRepairsTime(
        tester,
        originOffset: const Duration(hours: -2, minutes: -55),
      );
    },
  );

  phase114Widgets(
    'Phase 114 repro: dismissing the picker books nothing for an illegal return prefill',
    (tester) async {
      final c = reservations();
      final opened = <String>[];
      final ride = origin(
        StockholmSchedule.stockholmNow().subtract(const Duration(hours: 4)),
      );
      await pumpApp(
        tester,
        PlanReturnRidePage(
          origin: ride,
          controller: c,
          onScheduled: (context, id) async => opened.add(id),
        ),
      );

      await tapSchedule(tester);
      await waitForNextStep(tester);
      expect(find.byType(ConfirmPickupSpot), findsNothing);
      expect(find.byType(ScheduleDateTimeSelector), findsOneWidget);

      moveraNavigatorKey.currentState!.pop();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(ScheduleDateTimeSelector), findsNothing);
      expect(find.byType(ConfirmPickupSpot), findsNothing);
      expect(find.byType(SelectRide), findsOneWidget);
      expect(c.all, isEmpty);
      expect(opened, isEmpty);
    },
  );

  phase114Widgets(
    'Phase 114 regression guard: a legal return prefill still books without the picker',
    (tester) async {
      final c = reservations();
      final opened = <String>[];
      final ride = origin(
        StockholmSchedule.roundToFive(
          StockholmSchedule.stockholmNow().add(const Duration(hours: 1)),
        ),
      );
      final prefill = ride.scheduledPickupAt.add(const Duration(hours: 3));
      await pumpApp(
        tester,
        PlanReturnRidePage(
          origin: ride,
          controller: c,
          onScheduled: (context, id) async => opened.add(id),
        ),
      );

      await tapSchedule(tester);
      await waitForNextStep(tester);
      expect(find.byType(ScheduleDateTimeSelector), findsNothing);
      await confirmPickupSpot(tester);
      await settleBooking(tester, opened);

      expect(c.all, hasLength(1));
      expect(c.all.single.scheduledPickupAt, prefill);
      expect(c.all.single.parentReservationId, 'rsv_origin');
      expect(opened, [c.all.single.reservationId]);
    },
  );

  phase114Widgets(
    'Phase 136 repro: an off-grid but otherwise legal return prefill still goes through the validated picker',
    (tester) async {
      final now = StockholmSchedule.stockholmNow();
      final onGridSoon = StockholmSchedule.roundToFive(
        DateTime(
          now.year,
          now.month,
          now.day,
          now.hour,
          now.minute,
        ).add(const Duration(hours: 2)),
      );
      // +2 min keeps the offset off-grid through the +3h return prefill,
      // since 3 hours is an exact multiple of the 5-minute slot.
      final offGridOriginPickup = onGridSoon.add(const Duration(minutes: 2));
      final ride = origin(offGridOriginPickup);
      final prefill = ride.scheduledPickupAt.add(const Duration(hours: 3));
      expect(
        StockholmSchedule.isLegalPickup(prefill),
        isTrue,
        reason: 'precondition: origin + 3 h is well past the 30-minute lead',
      );
      expect(
        StockholmSchedule.isOnGrid(prefill),
        isFalse,
        reason: 'precondition: origin + 3 h keeps the 2-minute off-grid offset',
      );

      final c = reservations();
      final opened = <String>[];
      await pumpApp(
        tester,
        PlanReturnRidePage(
          origin: ride,
          controller: c,
          onScheduled: (context, id) async => opened.add(id),
        ),
      );

      await tapSchedule(tester);
      await waitForNextStep(tester);

      expect(
        find.byType(ConfirmPickupSpot),
        findsNothing,
        reason: 'an off-grid prefill must not skip straight to pickup confirm',
      );
      expect(
        find.byType(ScheduleDateTimeSelector),
        findsOneWidget,
        reason:
            'an off-grid return prefill must open the shared validated picker',
      );
      expect(c.all, isEmpty);

      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();
      await confirmPickupSpot(tester);
      await settleBooking(tester, opened);

      expect(c.all, hasLength(1));
      final booked = c.all.single;
      expect(opened, [booked.reservationId]);
      expect(booked.parentReservationId, 'rsv_origin');
      expect(
        StockholmSchedule.isOnGrid(booked.scheduledPickupAt),
        isTrue,
        reason: 'the picker grid-aligns the final booked time',
      );
    },
  );

  phase114Widgets(
    'Phase 114 regression guard: main Schedule flow books its picked time without reopening the picker',
    (tester) async {
      final c = reservations();
      final opened = <String>[];
      final picked = StockholmSchedule.minimumPickup().add(
        const Duration(hours: 2),
      );
      await pumpApp(
        tester,
        SelectRide(
          pickupAddress: 'Klockarvägen 37',
          destinationAddress: 'Arlanda Express',
          pickupPosition: const LatLng(59.19, 17.62),
          destinationPosition: const LatLng(59.65, 17.93),
          bookingMode: BookingMode.scheduled,
          lockBookingMode: true,
          initialScheduledFor: picked,
          pickupAlreadyConfirmed: true,
          reservations: c,
          onScheduled: (context, id) async => opened.add(id),
        ),
      );

      await tapSchedule(tester);
      await settleBooking(tester, opened);

      expect(find.byType(ScheduleDateTimeSelector), findsNothing);
      expect(c.all, hasLength(1));
      expect(c.all.single.scheduledPickupAt, picked);
      expect(c.all.single.parentReservationId, isNull);
      expect(opened, [c.all.single.reservationId]);
    },
  );
}
