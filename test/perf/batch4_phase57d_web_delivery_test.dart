import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('57D web delivery keeps repeat-load caching enabled', () {
    final workflow = File('.github/workflows/publish-web-live.yml').readAsStringSync();

    expect(workflow, isNot(contains('--pwa-strategy=none')));
    expect(workflow, contains('flutter build web --release'));
  });

  test('57D Google Maps loader does not block first paint', () {
    final workflow = File('.github/workflows/publish-web-live.yml').readAsStringSync();

    expect(
      workflow,
      contains('maps.googleapis.com/maps/api/js?key='),
    );
    expect(workflow, contains('async defer></script>'));
  });
}
