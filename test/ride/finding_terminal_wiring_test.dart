import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Finding presentation owns external-terminal navigation', () {
    final source = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();

    expect(source, contains('onTerminal: (status)'));
    expect(source, contains('_leaving = true;'));
    expect(source, contains('WidgetsBinding.instance.addPostFrameCallback'));
    expect(source, contains('RideNavigator.home(context, status: status)'));
  });
}
