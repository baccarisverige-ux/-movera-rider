import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/core/api/safety_mock_api.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/features/safety/application/emergency_call_service.dart';
import 'package:movera_rider/features/safety/application/ride_check_controller.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/data/safety_data_sources.dart';
import 'package:movera_rider/features/safety/data/safety_repository.dart';
import 'package:movera_rider/features/safety/data/safety_store.dart';
import 'package:movera_rider/features/safety/domain/ride_check.dart';
import 'package:movera_rider/features/safety/domain/ride_check_monitor.dart';
import 'package:movera_rider/features/safety/domain/ride_check_questions.dart';
import 'package:movera_rider/features/safety/domain/ride_check_record.dart';
import 'package:movera_rider/features/safety/domain/ride_check_trigger.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pickup = GeoPoint(59.3293, 18.0686);
const _destination = GeoPoint(59.3600, 18.0000);
const _plan = RideCheckPlan(
  pickup: _pickup,
  destination: _destination,
  destinationLabel: 'Solna centrum',
);

/// A point [meters] north of [from].
GeoPoint _north(GeoPoint from, double meters) =>
    GeoPoint(from.latitude + meters / 111320, from.longitude);

RideCheckMonitor _monitor({
  RideCheckTriggerSettings settings = const RideCheckTriggerSettings(),
}) => RideCheckMonitor(settings: settings, plan: _plan);

final _t0 = DateTime.utc(2026, 10, 15, 14, 0);

void main() {
  group('RC1 defaults and settings', () {
    test('the app defaults are 500 m, 4 min, 2 km / 50% and crash on', () {
      const settings = RideCheckTriggerSettings();
      expect(settings.droppedFarMeters, 500);
      expect(settings.longStopMinutes, 4);
      expect(settings.offRouteKm, 2);
      expect(settings.longerThanExpectedPercent, 50);
      for (final trigger in RideCheckTrigger.values) {
        expect(settings.isOn(trigger), isTrue, reason: trigger.name);
      }
      expect(const RideCheckPolicy().enabled, isTrue);
    });

    test('admin numbers and on/off are read from the policy JSON', () {
      final policy = RideCheckPolicy.fromJson({
        'enabled': true,
        'triggers': {
          'droppedFar': {'enabled': false, 'meters': 800},
          'longStop': {'enabled': true, 'minutes': 6},
          'offRoute': {'enabled': true, 'km': 3.5, 'longerPercent': 70},
          'possibleCrash': {'enabled': false},
        },
      });
      final t = policy.triggers;
      expect(t.droppedFarEnabled, isFalse);
      expect(t.droppedFarMeters, 800);
      expect(t.longStopMinutes, 6);
      expect(t.offRouteKm, 3.5);
      expect(t.longerThanExpectedPercent, 70);
      expect(policy.allows(RideCheckTrigger.droppedFar), isFalse);
      expect(policy.allows(RideCheckTrigger.possibleCrash), isFalse);
      expect(policy.allows(RideCheckTrigger.longStop), isTrue);
      // A round trip keeps them.
      final again = RideCheckPolicy.fromJson(policy.toJson());
      expect(again.triggers.toJson(), t.toJson());
    });

    test('bad admin numbers fall back to the app defaults', () {
      final t = RideCheckTriggerSettings.fromJson({
        'droppedFar': {'meters': -1},
        'longStop': {'minutes': 'four'},
        'offRoute': {'km': 0},
      });
      expect(t.droppedFarMeters, 500);
      expect(t.longStopMinutes, 4);
      expect(t.offRouteKm, 2);
    });

    test(
      'the mock API serves the trigger defaults and the rider cannot change them',
      () async {
        resetSafetyMockForProcess();
        final api = ApiClient(client: InProcessMockClient());
        final remote = ApiSafetyRemoteDataSource(api);
        final policy = await remote.getRideCheck();
        expect(policy.enabled, isTrue);
        expect(
          policy.triggers.toJson(),
          const RideCheckTriggerSettings().toJson(),
        );

        final patched = await remote.patchRideCheck(
          policy.copyWith(
            enabled: false,
            triggers: const RideCheckTriggerSettings(droppedFarEnabled: false),
          ),
        );
        expect(patched.enabled, isFalse);
        expect(patched.triggers.droppedFarEnabled, isTrue);
      },
    );

    test('QA and API names map to triggers', () {
      expect(parseRideCheckTrigger('droppedFar'), RideCheckTrigger.droppedFar);
      expect(parseRideCheckTrigger('long_stop'), RideCheckTrigger.longStop);
      expect(
        parseRideCheckTrigger('unexpectedStop'),
        RideCheckTrigger.longStop,
      );
      expect(
        parseRideCheckTrigger('routeDeviation'),
        RideCheckTrigger.offRoute,
      );
      expect(
        parseRideCheckTrigger('possibleCrash'),
        RideCheckTrigger.possibleCrash,
      );
      expect(parseRideCheckTrigger('nope'), isNull);
    });
  });

  group('RC1 dropped far away', () {
    test('fires when the trip ends more than 500 m from the drop-off', () {
      final monitor = _monitor();
      expect(monitor.tripEnded(_north(_destination, 450)), isNull);
      final hit = _monitor().tripEnded(_north(_destination, 1200));
      expect(hit?.trigger, RideCheckTrigger.droppedFar);
      expect(hit!.reason.distanceMeters, closeTo(1200, 15));
      expect(hit.reason.destinationLabel, 'Solna centrum');
    });

    test('uses the admin distance and stays quiet when off', () {
      final far = _north(_destination, 700);
      expect(
        _monitor(
          settings: const RideCheckTriggerSettings(droppedFarMeters: 800),
        ).tripEnded(far),
        isNull,
      );
      expect(
        _monitor(
          settings: const RideCheckTriggerSettings(droppedFarEnabled: false),
        ).tripEnded(_north(_destination, 3000)),
        isNull,
      );
    });
  });

  group('RC1 long stop', () {
    final stopAt = _north(_pickup, 2000);

    List<RideCheckSample> still(
      GeoPoint at,
      Duration length, {
      bool traffic = false,
    }) => [
      for (var s = 0; s <= length.inSeconds; s += 3)
        RideCheckSample(
          point: at,
          at: _t0.add(Duration(seconds: s)),
          inTraffic: traffic,
        ),
    ];

    RideCheckDetection? feed(
      RideCheckMonitor monitor,
      List<RideCheckSample> samples,
    ) {
      RideCheckDetection? hit;
      for (final sample in samples) {
        hit ??= monitor.addSample(sample);
      }
      return hit;
    }

    test('fires after 4 min without moving mid-trip', () {
      final monitor = _monitor();
      expect(
        feed(monitor, still(stopAt, const Duration(minutes: 3, seconds: 50))),
        isNull,
      );
      final hit = monitor.addSample(
        RideCheckSample(point: stopAt, at: _t0.add(const Duration(minutes: 4))),
      );
      expect(hit?.trigger, RideCheckTrigger.longStop);
      expect(hit!.reason.stoppedMinutes, 4);
      // Once per trip.
      expect(
        monitor.addSample(
          RideCheckSample(
            point: stopAt,
            at: _t0.add(const Duration(minutes: 9)),
          ),
        ),
        isNull,
      );
    });

    test('not at a planned stop, not in traffic, not when off', () {
      expect(
        feed(_monitor(), still(_pickup, const Duration(minutes: 6))),
        isNull,
      );
      expect(
        feed(
          _monitor(),
          still(_north(_destination, 80), const Duration(minutes: 6)),
        ),
        isNull,
      );
      expect(
        feed(
          _monitor(),
          still(stopAt, const Duration(minutes: 6), traffic: true),
        ),
        isNull,
      );
      expect(
        feed(
          _monitor(
            settings: const RideCheckTriggerSettings(longStopEnabled: false),
          ),
          still(stopAt, const Duration(minutes: 6)),
        ),
        isNull,
      );
      expect(
        feed(
          _monitor(
            settings: const RideCheckTriggerSettings(longStopMinutes: 8),
          ),
          still(stopAt, const Duration(minutes: 6)),
        ),
        isNull,
      );
    });

    test('a car that keeps moving never fires', () {
      final monitor = _monitor();
      RideCheckDetection? hit;
      for (var s = 0; s < 600; s += 3) {
        hit ??= monitor.addSample(
          RideCheckSample(
            point: _north(_pickup, s * 8.0),
            at: _t0.add(Duration(seconds: s)),
          ),
        );
      }
      expect(hit, isNull);
    });
  });

  group('RC1 off the route', () {
    final route = [_pickup, _north(_pickup, 5000)];

    test('fires more than 2 km off the road route', () {
      final monitor = _monitor()..setPlannedRoute(route);
      final near = GeoPoint(_pickup.latitude + 0.02, _pickup.longitude + 0.03);
      expect(
        monitor.addSample(
          RideCheckSample(point: near, at: _t0, etaSeconds: 1200),
        ),
        isNull,
      );
      final far = GeoPoint(_pickup.latitude + 0.02, _pickup.longitude + 0.045);
      final hit = monitor.addSample(
        RideCheckSample(point: far, at: _t0.add(const Duration(seconds: 3))),
      );
      expect(hit?.trigger, RideCheckTrigger.offRoute);
      expect(hit!.reason.distanceMeters, greaterThan(2000));
    });

    test('without a road route only the time rule applies', () {
      final monitor = _monitor();
      final far = GeoPoint(_pickup.latitude, _pickup.longitude + 0.2);
      expect(
        monitor.addSample(
          RideCheckSample(point: far, at: _t0, etaSeconds: 600),
        ),
        isNull,
      );
    });

    test('fires when the trip takes 50% longer than expected', () {
      final monitor = _monitor();
      var lat = _pickup.latitude;
      RideCheckDetection? hit;
      // Expected 10 min; drive on for 16 min.
      for (var s = 0; s <= 16 * 60; s += 30) {
        lat += 0.001;
        hit ??= monitor.addSample(
          RideCheckSample(
            point: GeoPoint(lat, _pickup.longitude),
            at: _t0.add(Duration(seconds: s)),
            etaSeconds: s == 0 ? 600 : null,
          ),
        );
        if (s < 15 * 60) expect(hit, isNull, reason: 'at $s s');
      }
      expect(hit?.trigger, RideCheckTrigger.offRoute);
      expect(hit!.reason.longerPercent, greaterThanOrEqualTo(50));
    });

    test(
      'a short trip a few minutes late does not fire, and off means off',
      () {
        final monitor = _monitor();
        var hit = monitor.addSample(
          RideCheckSample(point: _pickup, at: _t0, etaSeconds: 120),
        );
        hit ??= monitor.addSample(
          RideCheckSample(
            point: _north(_pickup, 500),
            at: _t0.add(const Duration(minutes: 4)),
          ),
        );
        expect(hit, isNull);

        final off = _monitor(
          settings: const RideCheckTriggerSettings(offRouteEnabled: false),
        )..setPlannedRoute(route);
        expect(
          off.addSample(
            RideCheckSample(
              point: GeoPoint(_pickup.latitude, _pickup.longitude + 0.2),
              at: _t0,
              etaSeconds: 60,
            ),
          ),
          isNull,
        );
      },
    );
  });

  group('RC1 possible crash', () {
    RideCheckDetection? drive(
      RideCheckMonitor monitor,
      List<double> metersPerStep,
    ) {
      var at = _pickup;
      RideCheckDetection? hit;
      for (final (i, step) in metersPerStep.indexed) {
        at = _north(at, step);
        hit ??= monitor.addSample(
          RideCheckSample(
            point: at,
            at: _t0.add(Duration(seconds: 3 * i)),
          ),
        );
      }
      return hit;
    }

    test('a very hard stop from 50 km/h fires', () {
      // ~14 m/s, then standing still within one fix.
      final hit = drive(_monitor(), [0, 42, 42, 42, 1, 0]);
      expect(hit?.trigger, RideCheckTrigger.possibleCrash);
    });

    test('a normal stop, a GPS jump or crash off does not fire', () {
      expect(drive(_monitor(), [0, 42, 30, 18, 8, 2, 0]), isNull);
      expect(drive(_monitor(), [0, 900, 0, 0]), isNull);
      expect(
        drive(
          _monitor(
            settings: const RideCheckTriggerSettings(
              possibleCrashEnabled: false,
            ),
          ),
          [0, 42, 42, 42, 1, 0],
        ),
        isNull,
      );
    });
  });

  group('RC3 rider rows', () {
    List<String> labels(RideCheckTrigger trigger) => [
      for (final row in rideCheckRowsFor(trigger)) row.label,
    ];

    test('the three red rows come first for every trigger', () {
      for (final trigger in RideCheckTrigger.values) {
        final rows = rideCheckRowsFor(trigger);
        expect(rows.take(3).every((row) => row.red), isTrue);
        expect(rows.skip(3).any((row) => row.red), isFalse);
        expect(labels(trigger).take(3), [
          'There was an accident',
          'Someone is hurt or feels ill',
          'I feel unsafe',
        ]);
      }
    });

    test('each trigger has its own rows', () {
      expect(labels(RideCheckTrigger.droppedFar).skip(3), [
        'I was left at the wrong place',
        'The driver asked me to leave the car',
        'The car broke down',
        'Something else',
      ]);
      expect(labels(RideCheckTrigger.longStop).skip(3), [
        'I asked the driver to stop',
        'The car broke down',
        'Something else',
      ]);
      expect(labels(RideCheckTrigger.offRoute).skip(3), [
        'I asked for this route',
        'The car broke down',
        'Something else',
      ]);
      expect(
        labels(RideCheckTrigger.possibleCrash),
        labels(RideCheckTrigger.longStop),
      );
    });

    test('follow-ups ask what the spec asks', () {
      final accident = rideCheckRow(RideCheckRowId.accident).followUp;
      expect(
        [for (final q in accident.questions) q.text],
        [
          'Is anyone hurt?',
          'Is the car in a safe place?',
          'Is the other person OK?',
        ],
      );
      final hurt = rideCheckRow(RideCheckRowId.hurt).followUp.questions.single;
      expect(
        [for (final o in hurt.options) o.label],
        ['Me', 'The driver', 'Someone else'],
      );
      expect(
        rideCheckRow(RideCheckRowId.unsafe).followUp.questions.single.text,
        'Are you in danger right now?',
      );
      expect(
        rideCheckRow(
          RideCheckRowId.carBrokeDown,
        ).followUp.questions.single.text,
        'Can you continue the trip?',
      );
      expect(
        rideCheckRow(RideCheckRowId.somethingElse).followUp.asksForNote,
        isTrue,
      );
      expect(
        rideCheckRow(RideCheckRowId.wrongPlace).followUp.thanksOnly,
        isTrue,
      );
    });
  });

  group('RC4 answers endpoint', () {
    setUp(resetSafetyMockForProcess);

    RideCheckSubmission submission({
      required bool alert,
      String? alertId,
      List<RideCheckAnswer> answers = const [],
    }) => RideCheckSubmission(
      checkId: 'rc_1',
      trigger: RideCheckTrigger.longStop,
      shownAt: _t0,
      answers: answers,
      alert: alert,
      alertId: alertId,
      reason: const RideCheckReason(stoppedMinutes: 4),
      context: const RideCheckTripContext(
        rideId: 'ride_1',
        riderName: 'Sara Lind',
        riderPhone: '+46701234567',
        driverId: 'drv_1',
        driverName: 'Elin',
        driverPlate: 'MVR 204',
        driverVehicle: 'Black Volvo XC40',
        pickup: RideCheckPlace(label: 'Odenplan', point: _pickup),
        destination: RideCheckPlace(
          label: 'Solna centrum',
          point: _destination,
        ),
      ),
    );

    test(
      'a red row sends the alert with rider, driver and trip; Yes updates it',
      () async {
        final remote = ApiSafetyRemoteDataSource(
          ApiClient(client: InProcessMockClient()),
        );
        final accident = rideCheckRow(RideCheckRowId.accident);
        final first = await remote.postRideCheckAnswers(
          submission(
            alert: true,
            answers: [RideCheckAnswer.row(accident, _t0)],
          ),
        );
        expect(first.alerted, isTrue);
        expect(first.alertStatus, 'sent');
        expect(first.recipients, ['admin', 'dispatch']);
        final mock = safetyMockForProcess();
        final alert = mock.rideCheckAlerts[first.alertId]!;
        expect(alert['rider'], {
          'id': 'rider-local',
          'name': 'Sara Lind',
          'phone': '+46701234567',
        });
        expect(alert['driver'], {
          'id': 'drv_1',
          'name': 'Elin',
          'plate': 'MVR 204',
          'vehicle': 'Black Volvo XC40',
        });
        expect((alert['trip'] as Map)['rideId'], 'ride_1');
        expect(
          ((alert['trip'] as Map)['destination'] as Map)['label'],
          'Solna centrum',
        );

        final hurt = accident.followUp.questions.first;
        final update = await remote.postRideCheckAnswers(
          submission(
            alert: true,
            alertId: first.alertId,
            answers: [
              RideCheckAnswer.row(accident, _t0),
              RideCheckAnswer.question(hurt, hurt.options.first, _t0),
            ],
          ),
        );
        expect(update.alertId, first.alertId);
        expect(update.alertStatus, 'updated');
        expect(mock.rideCheckAlerts, hasLength(1));
        expect(mock.rideCheckAnswers.single['answers'], hasLength(2));
      },
    );

    test("I'm OK is saved for the log without an alert", () async {
      final remote = ApiSafetyRemoteDataSource(
        ApiClient(client: InProcessMockClient()),
      );
      final receipt = await remote.postRideCheckAnswers(
        submission(alert: false, answers: [RideCheckAnswer.ok(_t0)]),
      );
      expect(receipt.alerted, isFalse);
      expect(safetyMockForProcess().rideCheckAlerts, isEmpty);
      expect(safetyMockForProcess().rideCheckAnswers.single['checkId'], 'rc_1');
    });

    test('an answer without a check or ride is refused', () async {
      final mock = safetyMockForProcess();
      final hit = mock.handle(
        method: 'POST',
        path: '/api/v1/safety/ridecheck/answers',
        body: const {'answers': []},
        requestId: 'r1',
      );
      expect(hit!.status, 422);
    });

    test('sign-out forgets answers and alerts', () async {
      final remote = ApiSafetyRemoteDataSource(
        ApiClient(client: InProcessMockClient()),
      );
      await remote.postRideCheckAnswers(submission(alert: true));
      final mock = safetyMockForProcess()..reset();
      expect(mock.rideCheckAnswers, isEmpty);
      expect(mock.rideCheckAlerts, isEmpty);
    });
  });

  group('RideCheckController gates', () {
    late SafetyController safety;
    late RideCheckController rideCheck;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      resetSafetyMockForProcess();
      SafetyStore.resetShared();
      SafetyRepository.resetShared();
      SafetyController.resetShared();
      safety = SafetyController(
        session: SafetyStore(
          local: PreferencesSafetyLocalDataSource(memoryOnly: true),
          remote: ApiSafetyRemoteDataSource(
            ApiClient(client: InProcessMockClient()),
          ),
        ),
        emergency: EmergencyCallService(dialer: RecordingEmergencyDialer()),
      );
      await safety.load();
      rideCheck = RideCheckController.forSafety(safety);
    });

    tearDown(() {
      rideCheck.dispose();
      RideCheckController.tripMonitoring = false;
    });

    test('opens once per trigger per ride, and never two at a time', () async {
      expect(
        await rideCheck.open(RideCheckTrigger.longStop, rideId: 'r1'),
        RideCheckOpenResult.shown,
      );
      expect(
        await rideCheck.open(RideCheckTrigger.offRoute, rideId: 'r1'),
        RideCheckOpenResult.busy,
      );
      rideCheck.imOk();
      await rideCheck.settle();
      expect(
        await rideCheck.open(RideCheckTrigger.longStop, rideId: 'r1'),
        RideCheckOpenResult.alreadyShown,
      );
      expect(
        await rideCheck.open(RideCheckTrigger.offRoute, rideId: 'r1'),
        RideCheckOpenResult.shown,
      );
    });

    test(
      'a trigger Movera turned off, or the rider switched off, does not open',
      () async {
        safetyMockForProcess().rideCheck['triggers'] = {
          ...SafetyMockApi.defaultRideCheckTriggers(),
          'longStop': {'enabled': false, 'minutes': 4},
        };
        await safety.load();
        expect(
          await rideCheck.open(RideCheckTrigger.longStop, rideId: 'r1'),
          RideCheckOpenResult.triggerOff,
        );
        expect(rideCheck.session, isNull);

        await safety.setRideCheck(false);
        expect(
          await rideCheck.open(RideCheckTrigger.offRoute, rideId: 'r1'),
          RideCheckOpenResult.riderOff,
        );
      },
    );

    test(
      'live samples open the card only while trip monitoring is on',
      () async {
        rideCheck.attachTrip(const RideCheckTripContext(rideId: 'r1'), _plan);
        final stopAt = _north(_pickup, 2000);
        void stand() {
          for (var s = 0; s <= 250; s += 5) {
            rideCheck.addSample(
              'r1',
              RideCheckSample(
                point: stopAt,
                at: _t0.add(Duration(seconds: s)),
              ),
            );
          }
        }

        stand();
        expect(rideCheck.session, isNull);

        RideCheckController.tripMonitoring = true;
        rideCheck.attachTrip(const RideCheckTripContext(rideId: 'r2'), _plan);
        for (var s = 0; s <= 250; s += 5) {
          rideCheck.addSample(
            'r2',
            RideCheckSample(
              point: stopAt,
              at: _t0.add(Duration(seconds: s)),
            ),
          );
        }
        await pumpEventQueue();
        expect(rideCheck.session?.trigger, RideCheckTrigger.longStop);
        expect(rideCheck.session?.reason.stoppedMinutes, 4);
      },
    );

    test(
      'the trip ending far from the drop-off opens "dropped far away"',
      () async {
        RideCheckController.tripMonitoring = true;
        rideCheck.attachTrip(
          const RideCheckTripContext(
            rideId: 'r3',
            destination: RideCheckPlace(label: 'Solna centrum'),
          ),
          _plan,
        );
        expect(
          await rideCheck.tripEnded('r3', _north(_destination, 300)),
          RideCheckOpenResult.noTrigger,
        );
        rideCheck.attachTrip(
          const RideCheckTripContext(
            rideId: 'r4',
            destination: RideCheckPlace(label: 'Solna centrum'),
          ),
          _plan,
        );
        expect(
          await rideCheck.tripEnded('r4', _north(_destination, 1200)),
          RideCheckOpenResult.shown,
        );
        expect(rideCheck.session!.reason.destinationLabel, 'Solna centrum');
        expect(
          rideCheck.session!.rows.map((row) => row.id),
          contains(RideCheckRowId.wrongPlace),
        );
      },
    );
  });
}
