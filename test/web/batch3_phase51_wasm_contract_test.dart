import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web conditional imports use js_interop so Wasm selects web implementations', () {
    const entrypoints = <String>[
      'lib/core/web/web_overlay.dart',
      'lib/core/web/web_ride_pagehide.dart',
      'lib/core/web/web_search_interrupted.dart',
      'lib/core/web/web_standalone.dart',
    ];
    for (final path in entrypoints) {
      final source = File(path).readAsStringSync();
      expect(source, contains('if (dart.library.js_interop)'));
      expect(source, isNot(contains('if (dart.library.html)')), reason: path);
    }
  });

  test('map platform controller remains framework-owned', () {
    final source = File('lib/shared/widgets/custom_google_map.dart').readAsStringSync();
    expect(source, isNot(contains('_mapController?.dispose')));
    expect(source, contains('_mapController = null'));
  });

  test('accessibility tap budget remains at least 48 logical pixels', () {
    final source = File('lib/shared/accessibility/a11y.dart').readAsStringSync();
    expect(source, contains('static const minTap = 48.0'));
  });
}
