import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_review.dart';
import 'package:movera_rider/features/reservations/presentation/review_changes.dart';
import 'package:movera_rider/features/reservations/presentation/ride_scheduled.dart';
import 'package:movera_rider/features/reservations/presentation/scheduled_ride_terms.dart';
import 'package:movera_rider/features/reservations/presentation/upcoming_reservation.dart';
import 'package:movera_rider/features/history/presentation/ride_history.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<ReservationController> seeded() async {
    final c = ReservationController(
      store: LocalReservationRepository(
        storage: MemoryReservationStorage(),
        nextId: () => 'rsv_ui',
      ),
    );
    await c.create(
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
    return c;
  }

  Future<void> pumpPhone(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: home));
  }

  testWidgets('confirmation shows Movera reservation card not a toast', (
    tester,
  ) async {
    final c = await seeded();
    await pumpPhone(
      tester,
      RideScheduledPage(reservationId: 'rsv_ui', controller: c),
    );
    expect(find.text('Your ride is scheduled'), findsOneWidget);
    expect(find.textContaining('notify you'), findsOneWidget);
    expect(find.text('Finding your driver later'), findsOneWidget);
    expect(find.text('View reservation'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Plan a return ride'), 400);
    expect(find.text('Plan a return ride'), findsOneWidget);
    expect(find.text('Bags · Pet'), findsOneWidget);
    expect(find.text('Your reservation is confirmed'), findsNothing);
    expect(find.textContaining('Uber'), findsNothing);
  });

  testWidgets('history lists the reservation immediately under Upcoming', (
    tester,
  ) async {
    final c = await seeded();
    await pumpPhone(tester, RideHistory(reservations: c));
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Klockarvägen 37 → Arlanda Express'), findsOneWidget);
    expect(find.text('Finding your driver later'), findsOneWidget);
    expect(find.text('No upcoming rides'), findsNothing);
  });

  testWidgets('details match the reservation and keep the same id on edit', (
    tester,
  ) async {
    final c = await seeded();
    await pumpPhone(
      tester,
      UpcomingReservationPage(reservationId: 'rsv_ui', controller: c),
    );
    expect(find.text('Upcoming ride'), findsOneWidget);
    expect(find.text('Klockarvägen 37'), findsWidgets);
    expect(find.text('Arlanda Express'), findsWidgets);
    expect(find.text('Reservation confirmed'), findsOneWidget);
    expect(find.textContaining('when a driver is assigned'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Bags · Pet'), 300);
    expect(find.text('Preferences'), findsOneWidget);
    expect(find.text('Bags · Pet'), findsWidgets);
    expect(c.byId('rsv_ui')!.paymentMethod, 'Cash');
    await c.update(
      'rsv_ui',
      ReservationPatch(scheduledPickupAt: DateTime(2026, 9, 24, 8, 15)),
    );
    await tester.pump();
    expect(c.byId('rsv_ui')!.reservationId, 'rsv_ui');
    expect(c.byId('rsv_ui')!.scheduledPickupAt, DateTime(2026, 9, 24, 8, 15));
    expect(c.byId('rsv_ui')!.paymentMethod, 'Cash');
    expect(c.byId('rsv_ui')!.destination.label, 'Arlanda Express');
  });

  testWidgets('assigned driver updates the same history card', (tester) async {
    final c = await seeded();
    await pumpPhone(tester, RideHistory(reservations: c));
    expect(find.text('Finding your driver later'), findsOneWidget);
    await c.assignMockDriver('rsv_ui');
    await tester.pump();
    expect(find.text('Driver assigned'), findsOneWidget);
    expect(find.text('Finding your driver later'), findsNothing);
    expect(c.all, hasLength(1));
  });

  testWidgets('cancel moves the same reservation to Cancelled', (tester) async {
    final c = await seeded();
    await c.cancel('rsv_ui', reason: 'plans_changed');
    await pumpPhone(tester, RideHistory(reservations: c));
    await tester.tap(find.text('Cancelled'));
    await tester.pumpAndSettle();
    expect(find.text('Klockarvägen 37 → Arlanda Express'), findsOneWidget);
    expect(c.cancelled().single.reservationId, 'rsv_ui');
  });

  testWidgets('policy page is Movera terms', (tester) async {
    final c = await seeded();
    await pumpPhone(tester, ScheduledRideTermsPage(controller: c));
    expect(find.text('Scheduled ride terms'), findsOneWidget);
    expect(find.textContaining('Uber'), findsNothing);
    expect(find.textContaining('SEK 160'), findsNothing);
  });

  testWidgets('review does not create a reservation until Schedule is tapped', (
    tester,
  ) async {
    final c = await seeded();
    final draft = ReservationDraft(
      scheduledPickupAt: DateTime(2026, 9, 23, 6, 55),
      pickup: const ReservationPlace(label: 'Klockarvägen 37'),
      destination: const ReservationPlace(label: 'Arlanda Express'),
      categoryId: 'movera',
      categoryName: 'Movera',
      categoryImage: 'assets/images/rides/movera.png',
      price: 522,
      paymentMethod: 'Cash',
    );
    await pumpPhone(
      tester,
      ReservationReviewPage(draft: draft, ctaLabel: 'Schedule Movera'),
    );
    expect(find.text('Your scheduled ride'), findsOneWidget);
    expect(find.text('Schedule Movera'), findsOneWidget);
    expect(find.textContaining('Uber'), findsNothing);
    expect(c.all, hasLength(1));
  });

  testWidgets('review changes compares price and keeps the current ride', (
    tester,
  ) async {
    final c = await seeded();
    final original = c.byId('rsv_ui')!;
    final draft = ReservationDraft(
      scheduledPickupAt: DateTime(2026, 9, 24, 8, 15),
      pickup: const ReservationPlace(label: 'T-Centralen'),
      destination: const ReservationPlace(label: 'Bromma'),
      categoryId: 'comfort',
      categoryName: 'Comfort',
      categoryImage: 'assets/images/rides/comfort.png',
      price: 562,
      paymentMethod: 'Cash',
    );
    await pumpPhone(
      tester,
      ReviewChangesPage(original: original, draft: draft, controller: c),
    );
    expect(find.text('Review your changes'), findsOneWidget);
    expect(find.text('Confirm changes'), findsOneWidget);
    expect(find.text('Keep current reservation'), findsOneWidget);
    expect(find.textContaining('40 kr more'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('No additional change charge'),
      300,
    );
    expect(find.text('No additional change charge'), findsOneWidget);
    expect(find.textContaining('Uber'), findsNothing);
    await tester.tap(find.text('Keep current reservation'));
    await tester.pump();
    expect(c.byId('rsv_ui')!.price, 522);
    expect(c.byId('rsv_ui')!.reservationId, 'rsv_ui');
  });
}
