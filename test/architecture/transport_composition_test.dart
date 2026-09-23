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

  test('production ApiClient never silently chooses in-process mock', () {
    final api = ApiClient(env: production);
    expect(api.usesMockTransport, isFalse);
  });

  test('dev/test may explicitly use in-process transport', () {
    final api = ApiClient(
      env: dev,
      client: InProcessMockClient(),
    );
    expect(api.usesMockTransport, isTrue);
  });

  test('production composition rejects mock realtime/payment/push', () {
    final api = ApiClient(env: production);
    final realtime = MockRideRealtime(api: api);

    expect(
      () => TransportComposition.validate(
        environment: production,
        api: api,
        realtime: realtime,
        paymentGateway: MockPaymentGateway(),
        push: NoopPushService(),
      ),
      throwsStateError,
    );

    realtime.dispose();
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
      ),
      returnsNormally,
    );

    realtime.dispose();
  });
}
