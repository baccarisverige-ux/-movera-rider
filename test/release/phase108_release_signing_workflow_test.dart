import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Batch 9 Phase 108 — D-027: the release-signing check must sign the
/// production composition, not the demo entrypoint.
void main() {
  final workflow = File(
    '.github/workflows/android-release-signing.yml',
  ).readAsStringSync();

  test('signing check builds the production entrypoint and flavor', () {
    expect(workflow, contains('flutter build apk --release'));
    expect(workflow, contains('-t lib/main_production.dart'));
    expect(workflow, contains('--dart-define=MOVERA_FLAVOR=production'));
    expect(workflow, contains('--dart-define=MOVERA_API_BASE_URL='));
    expect(workflow, isNot(contains('lib/main_demo.dart')));
  });

  test('signing check still rejects debug-signed output', () {
    expect(workflow, contains('apksigner'));
    expect(workflow, contains('Release APK is debug-signed'));
  });

  test(
    'production entrypoint refuses to start without the production flavor',
    () {
      final entry = File('lib/main_production.dart').readAsStringSync();
      expect(entry, contains('AppFlavor.production'));
      expect(entry, contains('throw StateError'));
    },
  );
}
