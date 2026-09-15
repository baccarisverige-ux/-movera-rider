import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/promotions/data/promotions_repository.dart';
import 'package:movera_rider/features/promotions/presentation/promotions.dart';

void main() {
  test('repository does not seed an unverified home campaign', () {
    expect(PromotionsRepository().homeCampaign(), isNull);
  });

  testWidgets('promotions and saved tabs show designed honest empty states', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Promotions()));

    expect(find.byIcon(Icons.local_offer_outlined), findsWidgets);
    expect(find.text('No promotions available'), findsOneWidget);
    expect(
      find.text(
        'New verified ride offers will appear here when they are available.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark_border_rounded), findsWidgets);
    expect(find.text('No saved promotions'), findsOneWidget);
    expect(find.text('Promotions you save will appear here.'), findsOneWidget);
  });

  test('fabricated promotion copy does not ship in lib', () {
    const banned = [
      'C2C5902X37T8',
      'Sed at risus magna',
      r'$106 extra',
      'Lorem ipsum',
      '10.08.2023',
      '40% off your next ride',
    ];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final source = files.map((file) => file.readAsStringSync()).join('\n');
    for (final value in banned) {
      expect(source, isNot(contains(value)), reason: 'Found fake copy: $value');
    }
  });
}
