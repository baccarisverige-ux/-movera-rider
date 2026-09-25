import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home destination flow awaits sheet animation instead of sleeping 360ms', () {
    final source = File(
      'lib/features/home/presentation/home.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('Duration(milliseconds: 360)')));
    expect(source, contains('await _openDestinationSheet();'));
    final sheetSource = File(
      'lib/features/home/application/home_sheet_controller.dart',
    ).readAsStringSync();
    expect(source, contains('await _sheetCtl.open();'));
    expect(sheetSource, contains('Future<void> open() => animateTo(const SheetOffset(1));'));
  });

  test('first-frame notification uses frame completion instead of fixed delay', () {
    final source = File(
      'lib/features/home/presentation/home.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('WidgetsBinding.instance.addPostFrameCallback'),
    );
  });
}
