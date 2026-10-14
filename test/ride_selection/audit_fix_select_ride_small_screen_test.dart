import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/features/ride_selection/presentation/select_ride.dart';
import 'package:movera_rider/features/ride_selection/presentation/select_ride_geometry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../responsive/responsive_harness.dart';

/// UI-1: SelectRide used to throw `ArgumentError` from `num.clamp` (upper
/// bound below the lower one) on any viewport shorter than 625 px, and the
/// whole screen was replaced by an ErrorWidget.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('max sheet height is defined on short screens', () {
    for (final size in const [Size(320, 568), Size(844, 390), Size(667, 375)]) {
      final height = selectRideMaxSheetHeight(MediaQueryData(size: size));
      expect(height, greaterThanOrEqualTo(300 + 64), reason: '$size');
    }
  });

  for (final size in const [
    Size(320, 568),
    Size(360, 616),
    Size(844, 390),
    Size(667, 375),
    Size(390, 380),
  ]) {
    testWidgets('SelectRide lays out at $size', (tester) async {
      SharedPreferences.setMockInitialValues({});
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await pumpMoveraScreen(
          tester,
          const SelectRide(
            pickupAddress: 'A',
            destinationAddress: 'B',
            pickupPosition: LatLng(59.3293, 18.0686),
            destinationPosition: LatLng(59.3326, 18.0649),
          ),
          viewport: size,
        );
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull);
        expect(find.byType(ErrorWidget), findsNothing);
        expect(find.text('Choose your ride'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 2));
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
