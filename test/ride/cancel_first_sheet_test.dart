import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/finding_driver/domain/cancellation_reason.dart';
import 'package:movera_rider/features/finding_driver/presentation/cancel_ride_sheet.dart';

/// Extends cancel_reason_test coverage for cancel-first orchestration.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> phoneSurface(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('Cancel request runs onCancelConfirmed before why-sheet', (
    tester,
  ) async {
    await phoneSurface(tester);
    final order = <String>[];
    CancelOutcome? outcome;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              outcome = await showCancelRideSheet(
                context,
                takingLonger: false,
                onCancelConfirmed: () async {
                  order.add('cancelled');
                },
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(order, isEmpty);
    await tester.tap(find.text('Cancel request'));
    await tester.pumpAndSettle();
    expect(order, ['cancelled']);
    expect(find.text('Why are you cancelling?'), findsOneWidget);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(outcome?.cancelled, isTrue);
  });

  testWidgets('Keep after Cancel request still stays cancelled', (
    tester,
  ) async {
    await phoneSurface(tester);
    var confirmed = false;
    CancelOutcome? outcome;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              outcome = await showCancelRideSheet(
                context,
                takingLonger: false,
                onCancelConfirmed: () async {
                  confirmed = true;
                },
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel request'));
    await tester.pumpAndSettle();
    expect(confirmed, isTrue);
    await tester.tap(find.text('Keep ride'));
    await tester.pumpAndSettle();
    expect(outcome?.cancelled, isTrue);
  });
  testWidgets('active-trip cancel stays reversible until the final step', (
    tester,
  ) async {
    await phoneSurface(tester);
    var committedEarly = false;
    CancelOutcome? outcome;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              outcome = await showCancelRideSheet(
                context,
                takingLonger: false,
                phase: CancelPhase.inTrip,
                onCancelConfirmed: () async {
                  committedEarly = true;
                },
              );
            },
            child: const Text('open-active-trip-cancel'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-active-trip-cancel'));
    await tester.pumpAndSettle();

    // First confirmation only opens the final reason/keep step.
    await tester.tap(find.text('Cancel ride'));
    await tester.pumpAndSettle();
    expect(committedEarly, isFalse);
    expect(find.text('Why are you cancelling?'), findsOneWidget);

    // Aborting the final step must keep the same active ride alive.
    await tester.tap(find.text('Keep ride'));
    await tester.pumpAndSettle();
    expect(outcome?.cancelled, isFalse);
    expect(committedEarly, isFalse);
  });

}
