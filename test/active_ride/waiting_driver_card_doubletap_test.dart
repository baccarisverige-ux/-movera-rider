import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_sheet_bits.dart';
import 'package:movera_rider/features/messages/presentation/chat.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';

/// Phase 133: WaitingDriverCard's "Message driver" button pushed Chat with
/// no guard, so a fast double-tap could stack two Chat screens. The card
/// was a StatelessWidget (nowhere to keep an in-flight flag), so it was
/// converted to a minimal StatefulWidget purely to hold that guard - its
/// build output and public constructor are unchanged.
void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const driver = MatchedDriver(id: 'd1', firstName: 'Erik');

  testWidgets('a double-tap on Message only opens Chat once', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: WaitingDriverCard(
              driver: driver,
              rideId: 'ride-133',
              onOpenProfile: () {},
              onCall: () {},
              onMore: () {},
            ),
          ),
        ),
      ),
    );

    final messageButton = find.text('Message');
    await tester.tap(messageButton, warnIfMissed: false);
    await tester.tap(messageButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.byType(Chat), findsOneWidget);

    // Popping and tapping again should still work (the guard only blocks
    // re-entry while a push is already in flight, not forever).
    Navigator.of(tester.element(find.byType(Chat))).pop();
    await tester.pumpAndSettle();
    await tester.tap(messageButton, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(Chat), findsOneWidget);
  });
}
