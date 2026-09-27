import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/schedule_ride.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 113: the scheduled "Plan your ride" screen must not offer stops.
///
/// Stops typed here reached `ScheduledRideSession.stops` →
/// `SelectRide(stops:)` and were then silently dropped (no stops in
/// `ReservationDraft`, no fare, no routing) — the same U5 problem Phase 100
/// closed on Home. Behavioural test only (no source reads).
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpSchedule(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => const MaterialApp(home: ScheduleRide()),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in const [Size(390, 844), Size(320, 568)]) {
    testWidgets('U5 (scheduled): no "Add a stop" control and no stop fields '
        'at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await pumpSchedule(tester, size);

      // The address step itself still renders as before.
      expect(find.text('Plan your ride'), findsOneWidget);
      expect(find.text('Pickup'), findsOneWidget);
      expect(find.text('Drop-off'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Only pickup + drop-off fields exist.
      expect(find.byType(TextField), findsNWidgets(2));

      // No way to add a stop.
      expect(find.text('Add a stop'), findsNothing);
      expect(find.byIcon(Icons.add_rounded), findsNothing);
      expect(find.textContaining('Stop 1'), findsNothing);
      expect(find.text('Remove stop'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('pickup and drop-off remain editable; Next enables on drop-off', (
    tester,
  ) async {
    await pumpSchedule(tester, const Size(390, 844));

    ElevatedButton next() => tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Next'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(next().onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'Arlanda Terminal 5');
    await tester.pump();
    expect(next().onPressed, isNotNull);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
