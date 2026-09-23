import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search has explicit backend-owned no-driver terminal state', () {
    final status = File(
      'lib/features/ride_booking/domain/ride_status.dart',
    ).readAsStringSync();

    expect(status, contains('noDriverFound'));
    expect(status, contains('this == RideStatus.noDriverFound'));
  });

  test('search delay is non-terminal and remains a searching state', () {
    final status = File(
      'lib/features/ride_booking/domain/ride_status.dart',
    ).readAsStringSync();

    expect(status, contains('searchDelayed'));
    expect(status, contains('this == RideStatus.searchDelayed'));
  });

  test('rider no-show is not fabricated as a local ride outcome', () {
    final controller = File(
      'lib/features/finding_driver/application/finding_driver_controller.dart',
    ).readAsStringSync();
    final surface = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();

    expect(controller, isNot(contains('noShow')));
    expect(controller, isNot(contains('no_show')));
    expect(surface, isNot(contains('noShow')));
    expect(surface, isNot(contains('no_show')));
  });
}
