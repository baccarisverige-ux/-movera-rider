import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/history/presentation/ride_history.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';

void main() {
  ReservationController controller({String id = 'rsv_hist'}) {
    return ReservationController(
      store: LocalReservationRepository(
        storage: MemoryReservationStorage(),
        nextId: () => id,
      ),
    );
  }

  final draft = ReservationDraft(
    scheduledPickupAt: DateTime(2026, 9, 23, 6, 55),
    pickup: const ReservationPlace(label: 'Klockarvägen 37'),
    destination: const ReservationPlace(label: 'T-Centralen'),
    categoryId: 'comfort',
    categoryName: 'Comfort',
    categoryImage: 'assets/images/rides/comfort.png',
    price: 339,
    paymentMethod: 'Cash',
  );

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  Future<void> pumpHistory(
    WidgetTester tester,
    ReservationController reservations,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: RideHistory(reservations: reservations)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('never booked: Completed and Cancelled are empty', (
    tester,
  ) async {
    await pumpHistory(tester, controller());

    expect(find.text('No upcoming rides'), findsOneWidget);
    expect(
      find.textContaining('a Scheduled Ride can get you there on time'),
      findsOneWidget,
    );
    expect(find.text('Schedule a ride'), findsOneWidget);

    await openTab(tester, 'Completed');
    expect(find.byIcon(Icons.route_outlined), findsOneWidget);
    expect(find.text('No completed rides yet'), findsOneWidget);
    expect(
      find.text('Completed trips and their real ride details will appear here.'),
      findsOneWidget,
    );
    expect(find.text('Book a ride'), findsOneWidget);

    await openTab(tester, 'Cancelled');
    expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
    expect(find.text('No cancelled rides'), findsOneWidget);
    expect(
      find.text(
        'Trips you cancel will appear here with their recorded reason.',
      ),
      findsOneWidget,
    );
    expect(find.text('Book a ride'), findsOneWidget);
  });

  testWidgets('a completed reservation shows in Completed, not Cancelled', (
    tester,
  ) async {
    final reservations = controller();
    await reservations.create(draft);
    await reservations.update(
      'rsv_hist',
      const ReservationPatch(status: ReservationStatus.completed),
    );
    await pumpHistory(tester, reservations);

    await openTab(tester, 'Completed');
    expect(find.text('No completed rides yet'), findsNothing);
    expect(find.textContaining('T-Centralen'), findsWidgets);

    await openTab(tester, 'Cancelled');
    expect(find.text('No cancelled rides'), findsOneWidget);
  });

  testWidgets('a cancelled reservation shows in Cancelled, not Completed', (
    tester,
  ) async {
    final reservations = controller();
    await reservations.create(draft);
    await reservations.cancel('rsv_hist', reason: 'plans_changed');
    await pumpHistory(tester, reservations);

    await openTab(tester, 'Cancelled');
    expect(find.text('No cancelled rides'), findsNothing);
    expect(find.textContaining('T-Centralen'), findsWidgets);

    await openTab(tester, 'Completed');
    expect(find.text('No completed rides yet'), findsOneWidget);
  });

  test('history screen owns no hardcoded ride list', () {
    final source = File(
      'lib/features/history/presentation/ride_history.dart',
    ).readAsStringSync();
    // The static demo list lived in features/ride_history; it must stay gone.
    expect(source.contains('RideHistoryController'), isFalse);
    expect(source.contains('RideHistoryItem'), isFalse);
    expect(source.contains('features/ride_history'), isFalse);
    expect(source.contains('Alby Centrum'), isFalse);
    expect(Directory('lib/features/ride_history').existsSync(), isFalse);
  });
}
