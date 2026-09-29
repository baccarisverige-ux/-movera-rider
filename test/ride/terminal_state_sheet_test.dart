import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/active_ride/presentation/ride_terminal_state_sheet.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  for (final status in const <RideStatus>[
    RideStatus.noDriverFound,
    RideStatus.bookingExpired,
    RideStatus.paymentFailed,
    RideStatus.cancelledBySystem,
  ]) {
    testWidgets('terminal state ${status.name} renders and acknowledges', (
      tester,
    ) async {
      var acknowledged = false;
      final spec = RideTerminalStateSpec.fromStatus(status);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RideTerminalStateSheet(
              status: status,
              spec: spec,
              onAcknowledge: () => acknowledged = true,
            ),
          ),
        ),
      );

      expect(
        find.byKey(ValueKey<String>('ride-terminal-state-${status.name}')),
        findsOneWidget,
      );
      expect(find.text(spec.title), findsOneWidget);
      expect(find.text(spec.message), findsOneWidget);
      expect(find.text(spec.primaryLabel), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('ride-terminal-acknowledge')),
      );
      await tester.pump();

      expect(acknowledged, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  test('non-operational terminal status gets a safe fallback', () {
    final spec = RideTerminalStateSpec.fromStatus(RideStatus.cancelledByRider);
    expect(spec.title, 'This ride is no longer active');
    expect(spec.primaryLabel, 'Back to home');
  });
}
