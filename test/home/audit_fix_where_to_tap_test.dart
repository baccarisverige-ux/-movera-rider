import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/home/presentation/widgets/where_to_card.dart';

import '../responsive/responsive_harness.dart';

/// UI-3: the whole "Where to?" card opens Where to, not only the 27 px band
/// around its text.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final viewport in const [Size(390, 844), Size(320, 568)]) {
    testWidgets('every height of the card is tappable at $viewport', (
      tester,
    ) async {
      var destination = 0;
      var schedule = 0;
      await pumpMoveraScreen(
        tester,
        Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: WhereToCard(
                destinationAddress: null,
                onDestinationTap: () => destination++,
                onOpenSchedule: () => schedule++,
              ),
            ),
          ),
        ),
        viewport: viewport,
      );
      await tester.pump();
      final card = tester.getRect(find.byType(WhereToCard));
      for (final dy in [
        4.0,
        10.0,
        card.height / 2,
        card.height - 10,
        card.height - 4,
      ]) {
        final before = destination;
        await tester.tapAt(Offset(card.left + 80, card.top + dy));
        await tester.pump(const Duration(milliseconds: 400));
        expect(destination, before + 1, reason: 'tap at dy=$dy missed');
      }
      // The schedule chip keeps its own target at the right edge.
      await tester.tapAt(Offset(card.right - 30, card.top + 6));
      await tester.pump(const Duration(milliseconds: 400));
      expect(schedule, 1);
      expect(destination, 5);
    });
  }
}
