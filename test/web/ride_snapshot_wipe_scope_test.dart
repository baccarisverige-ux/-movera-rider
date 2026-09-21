import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The document-load wipe used to run before Flutter booted and dropped
/// live rides on public Safari. The helper remains for QA clear only.
void main() {
  final wipe = File('web/movera_ride_snapshot_wipe.js').readAsStringSync();

  test('wipe is not invoked on document load', () {
    expect(
      wipe.contains('if (!isInstalledApp()) '
          'window.moveraWipeRideSnapshotStorage();'),
      isFalse,
    );
    expect(
      wipe.contains('\n  window.moveraWipeRideSnapshotStorage();'),
      isFalse,
      reason: 'auto-wipe on load sent riders Home after a Safari crash',
    );
  });

  test('both standalone signals are still detected', () {
    expect(wipe.contains("'(display-mode: standalone)'"), isTrue);
    expect(wipe.contains('navigator.standalone === true'), isTrue);
  });

  test('the wipe helper still exists for QA clear', () {
    expect(wipe.contains('movera_active_ride'), isTrue);
    expect(
      wipe.contains('window.moveraWipeRideSnapshotStorage = function'),
      isTrue,
    );
  });

  test('index.html still loads the wipe helper before booting Flutter', () {
    final index = File('web/index.html').readAsStringSync();
    final wipeAt = index.indexOf('movera_ride_snapshot_wipe.js');
    final bootAt = index.indexOf('flutter_bootstrap.js');
    expect(wipeAt, greaterThan(-1));
    expect(bootAt, greaterThan(-1));
    expect(wipeAt, lessThan(bootAt));
  });
}