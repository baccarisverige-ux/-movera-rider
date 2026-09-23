import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter bootstrap is deferred and cache cleanup never reloads startup', () {
    final html = File('web/index.html').readAsStringSync();

    expect(html, contains('src="flutter_bootstrap.js" defer'));
    expect(html, isNot(contains('location.reload()')));
    expect(html, contains('Promise.allSettled(tasks)'));
  });

  test('web fetch helper does not request stale browser cache', () {
    final html = File('web/index.html').readAsStringSync();

    expect(html, contains("cache: 'no-store'"));
    expect(html, isNot(contains("cache: 'force-cache'")));
  });
}
