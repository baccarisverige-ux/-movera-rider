import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/home/presentation/home.dart';
import 'package:movera_rider/features/home/presentation/widgets/premium_bottom_nav_item.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../responsive/responsive_harness.dart';

/// UI-2: on short phones the expanded Home sheet used to cut off its bottom
/// content (Help centre) behind the bottom navigation, with no way to reach
/// it. The content now scrolls inside the sheet.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FindingDriverController.active = null;
    AppScope.instance.ride
      ..rideId = null
      ..suppressRestore = false
      ..restoreFromBackend(RideStatus.idle);
  });

  for (final (viewport, scale) in const [
    (Size(320, 568), 1.0),
    (Size(375, 667), 1.0),
    (Size(390, 844), 2.0),
  ]) {
    testWidgets('Help centre can be reached at $viewport text x$scale', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await pumpMoveraScreen(
          tester,
          const Home(),
          viewport: viewport,
          textScale: scale,
          useAppNavigatorKey: true,
        );
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        Future<void> dragUp(Finder from) async {
          await tester.timedDrag(
            from,
            const Offset(0, -900),
            const Duration(milliseconds: 300),
            warnIfMissed: false,
          );
          for (var i = 0; i < 15; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }

        // Open the sheet to the top stop, then scroll its content.
        await dragUp(find.bySemanticsLabel('Toggle home panel').first);
        await dragUp(find.text('Rides per week').first);

        final navTop = tester
            .getRect(find.byType(PremiumBottomNavItem).first)
            .top;
        final help = tester.getRect(find.text('Help centre'));
        expect(
          help.bottom,
          lessThanOrEqualTo(navTop),
          reason: 'Help centre ($help) must scroll above the nav ($navTop)',
        );
        expect(help.top, greaterThanOrEqualTo(0));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 2));
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
