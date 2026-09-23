import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FindingDrivers.dispose never cancels the rider business flow', () {
    final source = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();

    final disposeStart = source.indexOf('@override\n  void dispose()');
    final disposeEnd = source.indexOf(
      '  void _syncSheetOverlay()',
      disposeStart,
    );

    expect(disposeStart, greaterThanOrEqualTo(0));
    expect(disposeEnd, greaterThan(disposeStart));

    final disposeBody = source.substring(disposeStart, disposeEnd);
    expect(disposeBody, isNot(contains('cancelSearch(')));

    // Cancellation still exists behind the explicit rider-confirmed path.
    expect(
      source,
      contains('_match.cancelSearch(reasonId: outcome.reasonId)'),
    );
  });
}
