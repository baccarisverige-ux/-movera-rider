import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('machine-specific files are not tracked by git', () {
    final result = Process.runSync('git', ['ls-files']);
    expect(result.exitCode, 0, reason: result.stderr.toString());

    final tracked = (result.stdout as String).split('\n').toSet();
    const exactFiles = {
      '.flutter-plugins-dependencies',
      'android/local.properties',
      'tatus',
    };

    for (final path in tracked) {
      expect(
        path == '.dart_tool' || path.startsWith('.dart_tool/'),
        isFalse,
        reason: 'Dart generated file is tracked: $path',
      );
      expect(
        path == 'android/.gradle' || path.startsWith('android/.gradle/'),
        isFalse,
        reason: 'Android machine state is tracked: $path',
      );
    }
    for (final path in exactFiles) {
      expect(tracked, isNot(contains(path)), reason: 'Local file is tracked');
    }
  });
}
