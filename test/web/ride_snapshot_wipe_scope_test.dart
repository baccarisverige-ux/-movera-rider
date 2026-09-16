import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The document-load wipe runs before Flutter boots, so it — not Dart — has
/// the final say on whether a reloaded app still has a ride to restore.
/// Wiping unconditionally stranded installed-PWA riders on Home mid-booking.
void main() {
  final wipe = File('web/movera_ride_snapshot_wipe.js').readAsStringSync();

  test('wipe is skipped for an installed PWA', () {
    expect(wipe.contains('if (!isInstalledApp()) '
        'window.moveraWipeRideSnapshotStorage();'), isTrue);
    expect(
      wipe.contains('\n  window.moveraWipeRideSnapshotStorage();'),
      isFalse,
      reason: 'an unconditional call would wipe installed apps again',
    );
  });

  test('both standalone signals are checked', () {
    expect(wipe.contains("'(display-mode: standalone)'"), isTrue);
    expect(wipe.contains('navigator.standalone === true'), isTrue);
  });

  test('the wipe still exists for browser tabs', () {
    expect(wipe.contains('movera_active_ride'), isTrue);
    expect(wipe.contains('window.moveraWipeRideSnapshotStorage = function'), isTrue);
  });

  test('index.html still loads the wipe before booting Flutter', () {
    final index = File('web/index.html').readAsStringSync();
    final wipeAt = index.indexOf('movera_ride_snapshot_wipe.js');
    final bootAt = index.indexOf('flutter_bootstrap.js');
    expect(wipeAt, greaterThan(-1));
    expect(bootAt, greaterThan(-1));
    expect(wipeAt, lessThan(bootAt));
  });
}
