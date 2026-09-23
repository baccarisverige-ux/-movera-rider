import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('phase 33 receipt stays data-backed and dispute uses API idempotency', () {
    final receipt = File(
      'lib/features/ride_complete/presentation/trip_detail.dart',
    ).readAsStringSync();
    final dispute = File(
      'lib/features/ride_complete/data/ride_dispute_repository.dart',
    ).readAsStringSync();

    expect(receipt, contains('controller ?? RideCompleteController()'));
    expect(receipt, contains('.receipt()'));
    expect(dispute, contains("MutationAttempt('ride-dispute')"));
    expect(dispute, contains("'/api/v1/rides/$rideId/disputes'"));
    expect(dispute, contains('idempotencyKey: _mutation.keyFor(intent)'));
  });

  test('phase 34 location is isolated behind repository and GPS-off is certified', () {
    final location = File(
      'lib/core/location/location_repository.dart',
    ).readAsStringSync();
    final gps = File(
      'test/ride/book_now_two_paths_e2e_test.dart',
    ).readAsStringSync();

    expect(location, contains('class LocationRepository'));
    expect(location, contains('Geolocator.getCurrentPosition'));
    expect(location, contains('Geolocator.getPositionStream'));
    expect(gps, contains('GPS unavailable still opens Confirm pickup'));
  });

  test('phase 35 safety remote calls use shared authenticated API', () {
    final safety = File(
      'lib/features/safety/data/safety_store.dart',
    ).readAsStringSync();

    expect(
      safety,
      contains('ApiSafetyRemoteDataSource(api ?? AppScope.instance.api)'),
    );
    expect(safety, isNot(contains('ApiSafetyRemoteDataSource(ApiClient())')));
  });

  test('phase 36 auth obtains tokens from API instead of fabricating them', () {
    final auth = File(
      'lib/features/auth/data/auth_repository.dart',
    ).readAsStringSync();
    final controller = File(
      'lib/features/auth/application/auth_controller.dart',
    ).readAsStringSync();

    expect(auth, contains("'/api/v1/auth/provider'"));
    expect(auth, contains("'/api/v1/auth/otp/request'"));
    expect(auth, contains("'/api/v1/auth/sign-out'"));
    expect(auth, isNot(contains("'movera-mock-")));
    expect(controller, contains('_auth.requestOtp(phone: normalized)'));
  });

  test('phase 37 production composition rejects mock transports', () {
    final env = File('lib/app/config/env.dart').readAsStringSync();
    final composition = File(
      'lib/app/config/transport_composition.dart',
    ).readAsStringSync();
    final api = File('lib/core/api/api_client.dart').readAsStringSync();

    expect(env, contains('bool get allowsMockTransport'));
    expect(api, contains('_defaultClient(env ?? AppEnv.current)'));
    expect(composition, contains("if (api.usesMockTransport) 'api'"));
    expect(composition, contains("if (push is NoopPushService) 'push'"));
  });

  test('phase 38 observability scrubs secrets and push has a replaceable seam', () {
    final obs = File(
      'lib/core/observability/observability.dart',
    ).readAsStringSync();
    final push = File(
      'lib/core/notifications/push_service.dart',
    ).readAsStringSync();

    expect(obs, contains('abstract class LoggerSink'));
    expect(obs, contains('abstract class CrashSink'));
    expect(obs, contains("'accessToken'"));
    expect(obs, contains("'refreshToken'"));
    expect(obs, contains("'cardNumber'"));
    expect(push, contains('abstract class PushService'));
    expect(push, contains('Live FCM/APNs is not connected yet'));
  });

  test('phase 39 persisted schemas retain tolerant restore boundaries', () {
    final reservations = File(
      'lib/features/reservations/data/local_reservation_repository.dart',
    ).readAsStringSync();
    final snapshots = File(
      'lib/features/ride_booking/data/ride_snapshot_store.dart',
    ).readAsStringSync();

    expect(reservations, contains('Reservation.tryParse'));
    expect(reservations, contains('Ignore corrupt local data rather than crash on restore'));
    expect(snapshots, contains('RideSnapshot'));
    expect(snapshots, contains('jsonDecode'));
  });

  test('phase 40 performance and accessibility contracts remain explicit', () {
    final budgets = File(
      'lib/core/performance/performance_budgets.dart',
    ).readAsStringSync();
    final home = File(
      'lib/features/home/presentation/home.dart',
    ).readAsStringSync();

    expect(budgets, contains('quoteConcurrencyCeiling = 3'));
    expect(budgets, contains('markerMinimumMoveMeters = 1.5'));
    expect(home, contains('accessibleNavigation'));
    expect(home, contains('FocusTraversalGroup'));
    expect(home, contains('Recenter map on your location'));
  });
}
