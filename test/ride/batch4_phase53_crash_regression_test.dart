import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_sheet_bits.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget host(MatchedDriver driver) {
    return MaterialApp(
      home: Scaffold(
        body: WaitingDriverCard(
          driver: driver,
          rideId: 'phase53-driver-card',
          onOpenProfile: () {},
          onCall: () {},
          onMore: () {},
        ),
      ),
    );
  }

  testWidgets(
    'Waiting driver card does not crash when matching supplies an empty firstName',
    (tester) async {
      await tester.pumpWidget(
        host(const MatchedDriver(id: 'driver-empty', firstName: '')),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(WaitingDriverCard), findsOneWidget);
    },
  );

  testWidgets('Waiting driver card still renders a normal driver name', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const MatchedDriver(id: 'driver-amina', firstName: 'Amina')),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Amina'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });
}
