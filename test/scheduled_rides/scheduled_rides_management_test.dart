import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/scheduled_rides.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  ReservationController controller() {
    return ReservationController(
      store: LocalReservationRepository(
        storage: MemoryReservationStorage(),
        nextId: () => 'scheduled-management-1',
      ),
    );
  }

  Future<void> pumpPage(
    WidgetTester tester,
    ReservationController reservations,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(home: ScheduledRides(controller: reservations)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('fresh Scheduled Rides surface is honestly empty', (tester) async {
    await pumpPage(tester, controller());

    expect(find.text('Scheduled rides'), findsOneWidget);
    expect(find.text('No scheduled rides'), findsOneWidget);
    expect(find.text('Schedule a ride'), findsOneWidget);
    expect(find.textContaining('guarantee'), findsNothing);
    expect(find.textContaining('lock in your fare'), findsNothing);
  });

  testWidgets('upcoming reservation appears on the management surface', (
    tester,
  ) async {
    final reservations = controller();
    await reservations.create(
      ReservationDraft(
        scheduledPickupAt: DateTime(2026, 9, 23, 9, 30),
        pickup: const ReservationPlace(label: 'T-Centralen'),
        destination: const ReservationPlace(label: 'Arlanda Terminal 5'),
        categoryId: 'movera',
        categoryName: 'Movera',
        categoryImage: 'assets/images/rides/movera.webp',
        price: 289,
        paymentMethod: 'Apple Pay',
      ),
    );

    await pumpPage(tester, reservations);

    expect(find.textContaining('T-Centralen'), findsOneWidget);
    expect(find.textContaining('Arlanda Terminal 5'), findsOneWidget);
    expect(find.text('Schedule another ride'), findsOneWidget);
  });
}
