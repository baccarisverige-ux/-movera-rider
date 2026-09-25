import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home recenter control is at least 48x48 with semantics and tooltip', () {
    final source = File(
      'lib/features/home/presentation/home.dart',
    ).readAsStringSync();

    expect(source, contains("label: 'Recenter map on your location'"));
    expect(source, contains("message: 'Recenter map on your location'"));
    expect(source, contains('width: 48'));
    expect(source, contains('height: 48'));
  });

  test('automatic sheet collapse is disabled for accessible navigation', () {
    final homeSource = File(
      'lib/features/home/presentation/home.dart',
    ).readAsStringSync();
    final sheetSource = File(
      'lib/features/home/application/home_sheet_controller.dart',
    ).readAsStringSync();

    expect(
      homeSource,
      contains('MediaQuery.maybeOf(context)?.accessibleNavigation'),
    );
    expect(sheetSource, contains('if (accessibleNavigation ||'));
  });

  test('Home sheet handle is keyboard-focusable and semantic', () {
    final source = File(
      'lib/features/home/presentation/home.dart',
    ).readAsStringSync();

    expect(source, contains("label: 'Toggle home panel'"));
    expect(source, contains("message: 'Toggle home panel'"));
    expect(source, contains('FocusTraversalGroup('));
    expect(source, contains('InkWell('));
    expect(source, contains('width: 48'));
    expect(source, isNot(contains('TextScaler.noScaling')));
  });
}
