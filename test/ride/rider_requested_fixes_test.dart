import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_complete/presentation/add_tip.dart';

void main() {
  test('Finding and Waiting never render a different red pickup fallback', () {
    final finding = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();
    final waiting = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();

    for (final source in <String>[finding, waiting]) {
      expect(
        source,
        isNot(
          contains(
            'BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)',
          ),
        ),
      );
      expect(source, contains('if (_riderPuck != null)'));
      expect(source, contains('icon: _riderPuck!'));
    }
  });

  test('active trip exposes cancel directly and through Trip details', () {
    final waiting = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();
    final panel = File(
      'lib/features/active_ride/presentation/rider_in_trip_panel.dart',
    ).readAsStringSync();
    final phase = File(
      'lib/features/finding_driver/domain/cancellation_reason.dart',
    ).readAsStringSync();

    expect(waiting, contains('allowCancel: true'));
    expect(waiting, contains('CancelPhase.inTrip'));
    expect(waiting, contains('onCancel: _confirmCancel'));
    expect(panel, contains("ValueKey<String>('active-trip-cancel')"));
    expect(panel, contains("label: const Text('Cancel ride')"));
    expect(phase, contains('inTrip'));
  });

  testWidgets('custom tip works alongside fixed tip suggestions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: RideCompletedAddTip()),
        ),
      ),
    );

    expect(find.text('10 kr'), findsOneWidget);
    expect(find.text('20 kr'), findsOneWidget);
    expect(find.text('30 kr'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('custom-tip-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('custom-tip-field')),
      '45',
    );
    await tester.pump();

    expect(find.text('Custom tip: 45 kr selected.'), findsOneWidget);

    await tester.tap(find.text('20 kr'));
    await tester.pump();

    expect(find.text('20 kr selected.'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('custom-tip-field')),
    );
    expect(field.controller?.text, isEmpty);
  });
}
