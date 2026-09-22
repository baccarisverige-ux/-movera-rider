import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('finding and active ride surfaces consume the shared connection source',
      () {
    final di = File('lib/app/di.dart').readAsStringSync();
    final finding = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();
    final active = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();

    expect(
      di,
      contains('MockRideRealtime(api: api, connection: realtime)'),
      reason: 'ride transport and UI must observe the same connection source',
    );
    expect(finding, contains('RealtimeConnectionBanner('));
    expect(active, contains('RealtimeConnectionBanner('));
    expect(
      finding,
      contains('connection: AppScope.instance.realtime'),
    );
    expect(
      active,
      contains('connection: AppScope.instance.realtime'),
    );
  });
}
