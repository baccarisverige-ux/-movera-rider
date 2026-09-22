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
      'Navigator.push<bool>(\n      context,\n      RideStageTransition(',
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

  test('driver re-search reverses to the parked Finding route without stacking', () {
    final finding = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();
    final waiting = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();

    expect(finding, contains('final researchDriver = await Navigator.push<bool>('));
    expect(finding, contains('if (!mounted || researchDriver != true) return;'));
    expect(finding, contains('_resumeFindingAfterDriverCancel();'));

    final popExisting = waiting.indexOf('navigator.pop(true);');
    final coldRestoreFallback = waiting.indexOf('Navigator.pushReplacement(');
    expect(popExisting, greaterThanOrEqualTo(0));
    expect(coldRestoreFallback, greaterThan(popExisting));
    expect(
      waiting.substring(popExisting, coldRestoreFallback),
      contains('return;'),
      reason: 'normal driver re-search must not also stack a replacement Finding',
    );
  });

  test('Scheduled reverse navigation is step-aware and parks its platform map', () {
    final schedule = File(
      'lib/features/scheduled_rides/presentation/schedule_ride.dart',
    ).readAsStringSync();

    expect(schedule, contains('canPop: currentStep == 0'));
    expect(schedule, contains('if (!didPop) goToPreviousStep();'));
    expect(schedule, contains('onTap: goToPreviousStep'));
    expect(schedule, contains('Future<void> _withParkedScheduleMap('));
    expect(schedule, contains('setState(() => _mapParked = true)'));
    expect(schedule, contains('await WidgetsBinding.instance.endOfFrame'));
    expect(schedule, contains('_mapParked\n              ? const ColoredBox'));
    expect(schedule, contains('setState(() => _mapParked = false)'));
  });

  test('normal Home exit does not rebuild root; restored root still can', () {
    final navigator =
        File('lib/app/router/ride_navigator.dart').readAsStringSync();
    final restore = File(
      'lib/features/ride_booking/application/ride_restore_coordinator.dart',
    ).readAsStringSync();

    expect(
      navigator,
      contains('coordinator.goHome(replaceRoot: rootWasRestoredRide);'),
    );
    expect(
      navigator,
      contains('coordinator.showing != RestoredSurface.home'),
    );
    expect(restore, contains('void goHome({bool replaceRoot = true})'));
    expect(restore, contains('if (replaceRoot) onReplaceRoot?.call(const Home());'));
  });

}
