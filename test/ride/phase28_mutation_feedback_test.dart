import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/finding_driver/presentation/price_bump_card.dart';

void main() {
  testWidgets('busy price edit keeps card visible but disables mutation controls', (tester) async {
    var confirms = 0;
    var waits = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PriceBumpCard(
            currentPrice: 250,
            maxPrice: 450,
            steps: const <int>[50, 100],
            busy: true,
            onConfirm: (_) => confirms += 1,
            onKeepWaiting: () => waits += 1,
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.enabled, isFalse);

    final confirm = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(confirm.onPressed, isNull);

    for (final button in tester.widgetList<TextButton>(find.byType(TextButton))) {
      expect(button.onPressed, isNull);
    }

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(confirms, 0);
    expect(waits, 0);
  });

  test('finding screen exposes explicit pickup and offer mutation outcomes', () {
    final source = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();

    expect(source, contains('_showEditFeedback('));
    expect(source, contains("fallback: updated\n                  ? 'Pickup updated'"));
    expect(source, contains("'Couldn’t update pickup. Try again.'"));
    expect(source, contains("'Couldn’t update offer. Try again.'"));
    expect(source, contains('busy: _match.editInFlight'));
  });

  test('price bump remains renderable while edit is in flight', () {
    final source = File(
      'lib/features/finding_driver/application/finding_driver_controller.dart',
    ).readAsStringSync();

    final start = source.indexOf('bool get showPriceBump =>');
    final end = source.indexOf('double get currentPrice', start);
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));

    final block = source.substring(start, end);
    expect(block, isNot(contains('!_editInFlight')));
    expect(source, contains('bool get editInFlight => _editInFlight;'));
    expect(source, contains("editFeedback = 'Pickup updated';"));
    expect(source, contains("editFeedback = 'Couldn’t update offer. Try again.';"));
  });
}
