import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('installed Rider web shell declares standalone installability honestly', () {
    final manifest = jsonDecode(
      File('web/manifest.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(manifest['display'], 'standalone');
    expect(manifest['display_override'], contains('standalone'));
    expect(manifest['start_url'], '.');
    expect(manifest['scope'], '.');
    expect(manifest['orientation'], 'portrait-primary');
    expect(manifest['icons'], isA<List>());
    expect((manifest['icons'] as List).length, greaterThanOrEqualTo(4));
  });

  test('web shell preserves safe-area behavior used by installed iOS mode', () {
    final index = File('web/index.html').readAsStringSync();

    expect(
      index,
      contains(
        'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no',
      ),
    );
    expect(index, isNot(contains('viewport-fit=cover')));
    expect(index, contains('apple-mobile-web-app-capable'));
    expect(index, contains('apple-mobile-web-app-status-bar-style'));
    expect(index, contains('black-translucent'));
  });

  test('background/BFCache does not force reload or destroy an active ride', () {
    final index = File('web/index.html').readAsStringSync();

    expect(index, isNot(contains('if (event.persisted) location.reload()')));
    expect(index, isNot(contains("addEventListener('pagehide'")));
    expect(
      index,
      contains(
        'A page restored from the back-forward cache already retains its live',
      ),
    );
  });

  test('public web build intentionally avoids stale offline service workers', () {
    final index = File('web/index.html').readAsStringSync();

    expect(index, contains('navigator.serviceWorker.getRegistrations()'));
    expect(index, contains('registration.unregister()'));
    expect(index, contains('caches.keys()'));
    expect(index, contains('caches.delete(key)'));
    expect(
      index,
      contains('current non-PWA app'),
      reason:
          'The installed shell is standalone-capable but must not imply offline '
          'service-worker support that the production build intentionally removes.',
    );
  });
}
