import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/wallet/presentation/wallet.dart';

void main() {
  testWidgets('voucher action explains that redemption is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showVoucherUnavailableSheet(context),
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.confirmation_number_outlined), findsOneWidget);
    expect(find.text('Vouchers aren’t available yet'), findsOneWidget);
    expect(
      find.textContaining('when the service launches'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);
  });

  test('fabricated local voucher catalog does not ship', () {
    final source = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n');

    for (final banned in [
      'MOVERA100',
      'WELCOME50',
      'RIDE200',
      'MOVE25',
      'SUMMER75',
      'redeemVoucher',
      r'^KR(\d{2,4})-',
    ]) {
      expect(source, isNot(contains(banned)), reason: 'Found local voucher fixture: $banned');
    }
  });
}
