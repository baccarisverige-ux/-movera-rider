import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/app/config/transport_composition.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/core/notifications/push_service.dart';
import 'package:movera_rider/core/payments/mock_payment_gateway.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';

void main() {
  const production = AppEnv(
    flavor: AppFlavor.production,
    apiBaseUrl: 'https://api.movera.example',
    mapsEnabled: true,
  );
  const dev = AppEnv(
    flavor: AppFlavor.dev,
    apiBaseUrl: 'https://api.dev.movera.invalid',
    mapsEnabled: true,
  );
  const testEnv = AppEnv(
    flavor: AppFlavor.test,
    apiBaseUrl: 'https://api.test.movera.invalid',
    mapsEnabled: true,
  );
  const staging = AppEnv(
    flavor: AppFlavor.staging,
    apiBaseUrl: 'https://api.staging.movera.example',
    mapsEnabled: true,
  );

  test('production ApiClient never silently chooses in-process mock', () {
    final api = ApiClient(env: production);
    expect(api.usesMockTransport, isFalse);
  });

  test('dev/test may explicitly use in-process transport', () {
    for (final environment in <AppEnv>[dev, testEnv]) {
      final api = ApiClient(
        env: environment,
        client: InProcessMockClient(),
      );
      expect(api.usesMockTransport, isTrue);
    }
  });

  test('staging/production composition rejects mock realtime/payment/push', () {
    for (final environment in <AppEnv>[staging, production]) {
      final api = ApiClient(env: environment);
      final realtime = MockRideRealtime(api: api);

      expect(
        () => TransportComposition.validate(
          environment: environment,
          api: api,
          realtime: realtime,
          paymentGateway: MockPaymentGateway(),
          push: NoopPushService(),
          usesMockDriverAssignment: true,
        ),
        throwsStateError,
      );

      realtime.dispose();
    }
  });

  test('dev composition accepts mock stack', () {
    final api = ApiClient(env: dev, client: InProcessMockClient());
    final realtime = MockRideRealtime(api: api);

    expect(
      () => TransportComposition.validate(
        environment: dev,
        api: api,
        realtime: realtime,
        paymentGateway: MockPaymentGateway(),
        push: NoopPushService(),
        usesMockDriverAssignment: true,
      ),
      returnsNormally,
    );

    realtime.dispose();
  });

}
