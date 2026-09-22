import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ride stages use the quiet lifecycle transition', () {
    final transitions =
        File('lib/shared/widgets/navigation_transition.dart').readAsStringSync();
    final home =
        File('lib/features/home/presentation/home.dart').readAsStringSync();
    final select = File(
      'lib/features/ride_selection/presentation/select_ride.dart',
    ).readAsStringSync();
    final finding = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();
    final waiting = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();

    expect(transitions, contains('class RideStageTransition'));
    expect(transitions, contains('reverseTransitionDuration: Duration.zero'));
    expect(home, contains('RideStageTransition(\n          SelectRide('));
    expect(select, contains('RideStageTransition(\n            FindingDrivers('));
    expect(finding, contains('RideStageTransition(\n        WaitingForDriver('));
    expect(waiting, contains('RideStageTransition(\n        RideCompleted('));
  });

  test('matching map is parked before active ride map is mounted', () {
    final finding = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();

    final park = finding.indexOf('setState(() => _mapParked = true)');
    final push = finding.indexOf(
      'Navigator.push(\n      context,\n      RideStageTransition(',
    );

    expect(park, greaterThanOrEqualTo(0));
    expect(push, greaterThan(park));
    expect(
      finding.substring(park, push),
      contains('await WidgetsBinding.instance.endOfFrame'),
    );
  });

  test('active ride map is parked before completion and Home exits', () {
    final waiting = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();

    expect(waiting, contains('Future<void> _parkMapForStageChange()'));
    expect(
      waiting,
      contains('_mapParked\n                  ? const ColoredBox'),
    );
    expect(
      waiting,
      contains('await _parkMapForStageChange();\n    if (!mounted) return;'),
    );
  });
}
