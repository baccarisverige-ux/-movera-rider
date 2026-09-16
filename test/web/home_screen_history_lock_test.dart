import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('installed Home Screen app never installs browser history sentinel', () {
    final source = File('lib/core/web/web_overlay_web.dart').readAsStringSync();

    expect(source, contains("import 'package:movera_rider/core/web/web_standalone.dart';"));
    expect(source, contains('if (isInstalledWebApp()) return;'));
    expect(
      source.indexOf('if (isInstalledWebApp()) return;'),
      lessThan(source.indexOf('_installHomeLock();')),
    );
  });

  test('installed-app detection keeps both standard and iOS signals', () {
    final source =
        File('lib/core/web/web_standalone_web.dart').readAsStringSync();

    expect(source, contains("matchMedia('(display-mode: standalone)')"));
    expect(source, contains('_iosStandalone'));
  });
}
