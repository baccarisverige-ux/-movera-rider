import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/history/presentation/ride_history.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/schedule_ride.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NAV-12: "Schedule a ride" in the How it works sheet opens the schedule
/// map only after the sheet has finished closing, never on top of it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the schedule page never overlaps the closing sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reservations = ReservationController(
      store: LocalReservationRepository(storage: MemoryReservationStorage()),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: RideHistory(
          reservations: reservations,
          onDemandReader: () async => const [],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('How history works'));
    await tester.pumpAndSettle();
    expect(find.text('Scheduled rides'), findsOneWidget);

    await tester.tap(find.text('Schedule a ride').last);
    final sheet = find.text('Scheduled rides', skipOffstage: false);
    final schedule = find.byType(ScheduleRide, skipOffstage: false);
    var opened = false;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (schedule.evaluate().isEmpty) continue;
      opened = true;
      expect(sheet, findsNothing, reason: 'Schedule pushed over the sheet');
    }
    expect(opened, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });
}
