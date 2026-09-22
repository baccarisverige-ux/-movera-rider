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
    final rideStageStart = transitions.indexOf('class RideStageTransition');
    final rideStageEnd = transitions.indexOf('class SwitchTransition');
    expect(rideStageStart, greaterThanOrEqualTo(0));
    expect(rideStageEnd, greaterThan(rideStageStart));
    final rideStage = transitions.substring(rideStageStart, rideStageEnd);
    expect(rideStage, contains('reverseTransitionDuration: Duration.zero'));
    expect(
      rideStage,
      contains("const ColoredBox(color: Color(0xFFF6F5F1))"),
      reason: 'incoming ride stages need an opaque cover over the previous route',
    );
    expect(rideStage, contains('opacity: veil'));
    expect(
      rideStage,
      isNot(contains('FadeTransition(opacity: curved, child: child)')),
      reason: 'fading the entire incoming ride stage exposes the previous stage',
    );
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

  test('Ride Scheduled Back reverses one route while Done is the Home exit', () {
    final scheduled = File(
      'lib/features/reservations/presentation/ride_scheduled.dart',
    ).readAsStringSync();

    expect(scheduled, contains('void _goBack()'));
    expect(scheduled, contains('Navigator.maybePop(context);'));
    expect(scheduled, contains('onTap: _goBack'));
    expect(
      scheduled,
      contains("ReservationFillButton(label: 'Done', onTap: _closeHome)"),
    );
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


  test('live ride stages defer navigation while a child route is on top', () {
    final observer = File(
      'lib/app/router/home_history_observer.dart',
    ).readAsStringSync();
    final finding = File(
      'lib/features/finding_driver/presentation/finding_drivers.dart',
    ).readAsStringSync();
    final waiting = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();

    expect(observer, contains('moveraNavigationEpoch'));
    expect(observer, contains('moveraNavigationEpoch.value += 1'));

    expect(finding, contains('bool get _routeIsCurrent'));
    expect(finding, contains('_matchedPending'));
    expect(finding, contains('_terminalPending'));
    expect(finding, contains('moveraNavigationEpoch.addListener'));
    expect(finding, contains('_drainDeferredNavigation()'));
    expect(
      finding,
      contains('WidgetsBinding.instance.addPostFrameCallback'),
      reason: 'Finding must not push a stage while NavigatorObserver is locked',
    );
    expect(
      finding,
      contains('!_routeIsCurrent'),
      reason: 'Finding must not transition stages under a child route',
    );

    expect(waiting, contains('bool get _routeIsCurrent'));
    expect(waiting, contains('_pendingStageStatus'));
    expect(waiting, contains('moveraNavigationEpoch.addListener'));
    expect(waiting, contains('_queueStageNavigation'));
    expect(
      waiting,
      contains('WidgetsBinding.instance.addPostFrameCallback'),
      reason: 'Waiting must not push sheets/routes while NavigatorObserver is locked',
    );
    expect(
      waiting,
      contains('!_routeIsCurrent'),
      reason: 'Waiting must not transition stages under Chat/Safety/Profile/etc.',
    );
  });

  test('cold-restored Waiting re-search replaces only the restore-gate child', () {
    final waiting = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();
    final restore = File(
      'lib/features/ride_booking/application/ride_restore_coordinator.dart',
    ).readAsStringSync();

    expect(
      waiting,
      contains(
        'coordinator.replaceRootSurface(finding, RestoredSurface.finding)',
      ),
    );
    expect(restore, contains('bool replaceRootSurface('));
    expect(restore, contains('onReplaceRoot'));
    expect(restore, contains('showing = surface'));
  });



  test('cold-restored Waiting completion replaces only the restore-gate child', () {
    final waiting = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();

    final completionStart = waiting.indexOf(
      'final completed = RideCompleted(status: status, rideId: rideId);',
    );
    final rootGuard = waiting.indexOf('if (!navigator.canPop())', completionStart);
    final gateSwap = waiting.indexOf('RestoredSurface.complete', rootGuard);
    final routeReplace = waiting.indexOf(
      'navigator.pushReplacement(',
      gateSwap,
    );

    expect(completionStart, greaterThanOrEqualTo(0));
    expect(rootGuard, greaterThan(completionStart));
    expect(gateSwap, greaterThan(rootGuard));
    expect(routeReplace, greaterThan(gateSwap));
    expect(
      waiting.substring(rootGuard, routeReplace),
      contains('coordinator.replaceRootSurface('),
      reason:
          'cold completion must keep RideRestoreGate mounted so Done can reveal Home',
    );
  });


  test('Scheduled live uses reservation transport and reversible parent topology', () {
    final live = File(
      'lib/features/reservations/presentation/reservation_live_ride.dart',
    ).readAsStringSync();
    final upcoming = File(
      'lib/features/reservations/presentation/upcoming_reservation.dart',
    ).readAsStringSync();
    final chrono = File(
      'lib/features/reservations/presentation/home_reservation_chrono.dart',
    ).readAsStringSync();
    final waiting = File(
      'lib/features/active_ride/presentation/waiting_for_driver.dart',
    ).readAsStringSync();

    expect(live, contains('ReservationRideRealtime('));
    expect(live, contains('rideId: ride.reservationId'));
    expect(live, contains('persistRideSnapshot: false'));
    expect(live, contains('onDriverCancelled: (context) async'));
    expect(live, contains('Navigator.of(context).pop();'));
    expect(live, contains('persistOnDemandState: false'));
    expect(live, contains('showConnectionBanner: false'));

    expect(upcoming, contains('unawaited(_openLiveRide(ride));'));
    expect(upcoming, contains('_handedOff = false;'));
    expect(
      upcoming,
      isNot(contains('ReservationLiveRide.open(context, ride, replace: true)')),
      reason: 'Upcoming must remain underneath live ride for reverse navigation.',
    );

    expect(chrono, contains('Future<void> _openLiveRide(Reservation ride) async'));
    expect(chrono, contains('_openedLiveId = ride.reservationId;'));
    expect(chrono, contains('_openedLiveId = null;'));
    expect(
      chrono,
      contains('if (!mounted || !_routeIsCurrent || _openedLiveId == ride.reservationId) return;'),
      reason: 'manual and automatic chrono opens must share one duplicate guard',
    );

    expect(waiting, contains('final RideRealtime? realtime;'));
    expect(waiting, contains('final String? rideId;'));
    expect(waiting, contains('final bool persistRideSnapshot;'));
    expect(waiting, contains('final customDriverCancelled = widget.onDriverCancelled;'));
    expect(waiting, contains('final customCompleted = widget.onCompleted;'));
    expect(waiting, contains('final customCancel = widget.onCancel;'));
  });


  test('scheduled live handoff never hijacks an open child route', () {
    final chrono = File(
      'lib/features/reservations/presentation/home_reservation_chrono.dart',
    ).readAsStringSync();
    final upcoming = File(
      'lib/features/reservations/presentation/upcoming_reservation.dart',
    ).readAsStringSync();

    for (final source in <String>[chrono, upcoming]) {
      expect(source, contains('moveraNavigationEpoch.addListener'));
      expect(source, contains('moveraNavigationEpoch.removeListener'));
      expect(source, contains('bool get _routeIsCurrent'));
      expect(source, contains('!_routeIsCurrent'));
      expect(
        source,
        contains('WidgetsBinding.instance.addPostFrameCallback'),
        reason:
            'auto-handoff must retry only after Navigator finishes child-route changes',
      );
    }

    expect(
      chrono,
      contains('if (!mounted || !_routeIsCurrent) return;'),
      reason: 'Home chrono must not push a scheduled live ride over Profile/Wallet',
    );
    expect(
      upcoming,
      contains('_handedOff = false;'),
      reason: 'deferred Upcoming handoff must release its duplicate guard',
    );
  });


  test('Saved Places location chooser keeps Add Place as its reverse parent', () {
    final add = File(
      'lib/features/saved_places/presentation/add_place.dart',
    ).readAsStringSync();
    final pickup = File(
      'lib/features/saved_places/presentation/pickup_location.dart',
    ).readAsStringSync();

    expect(add, contains('class AddPlace extends StatefulWidget'));
    expect(add, contains('final selected = await Navigator.push<String>('));
    expect(add, isNot(contains('Navigator.pushReplacement(')));
    expect(add, contains('controller: _locationController'));
    expect(
      pickup,
      contains('this.allowCreateShortcut = true'),
    );
    expect(
      pickup,
      contains('if (!widget.allowCreateShortcut) return;'),
      reason: 'Add Place -> location search must not recurse into Add Place again',
    );
  });

}
