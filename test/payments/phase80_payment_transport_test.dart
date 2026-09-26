import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/core/payments/api_payment_gateway.dart';

void main() {
  const environment = AppEnv(
    flavor: AppFlavor.test,
    apiBaseUrl: 'https://api.test.movera.invalid',
    mapsEnabled: true,
  );

  test('Phase 80 creates confirms and reads backend payment intent', () async {
    final backend = InProcessMockClient();
    final gateway = ApiPaymentGateway(
      api: ApiClient(env: environment, client: backend),
    );

    final intent = await gateway.create(
      amountMinor: 12500,
      currency: 'sek',
      idempotencyKey: 'phase80-create',
    );

    expect(intent.id, isNotEmpty);
    expect(intent.amountMinor, 12500);
    expect(intent.currency, 'SEK');
    expect(await gateway.status(intent.id), 'requires_confirmation');
    expect(await gateway.confirm(intent.id), 'succeeded');
    expect(await gateway.status(intent.id), 'succeeded');
  });

  test('Phase 80 create is idempotent for the same payment intent', () async {
    final backend = InProcessMockClient();
    final gateway = ApiPaymentGateway(
      api: ApiClient(env: environment, client: backend),
    );

    final first = await gateway.create(
      amountMinor: 5000,
      currency: 'SEK',
      idempotencyKey: 'same-payment',
    );
    final second = await gateway.create(
      amountMinor: 5000,
      currency: 'SEK',
      idempotencyKey: 'same-payment',
    );

    expect(second.id, first.id);
    expect(backend.paymentIntents, hasLength(1));
  });

  test('reusing an idempotency key for another amount fails closed', () async {
    final backend = InProcessMockClient();
    final gateway = ApiPaymentGateway(
      api: ApiClient(env: environment, client: backend),
    );

    await gateway.create(
      amountMinor: 5000,
      currency: 'SEK',
      idempotencyKey: 'amount-bound-key',
    );

    await expectLater(
      gateway.create(
        amountMinor: 9000,
        currency: 'SEK',
        idempotencyKey: 'amount-bound-key',
      ),
      throwsA(isA<PaymentTransportException>()),
    );
  });

  test('invalid amount and intent ids are rejected before transport', () async {
    final backend = InProcessMockClient();
    final gateway = ApiPaymentGateway(
      api: ApiClient(env: environment, client: backend),
    );

    await expectLater(
      gateway.create(
        amountMinor: 0,
        currency: 'SEK',
        idempotencyKey: 'invalid',
      ),
      throwsA(isA<PaymentTransportException>()),
    );
    await expectLater(
      gateway.confirm('../wrong'),
      throwsA(isA<PaymentTransportException>()),
    );
    expect(backend.paymentIntents, isEmpty);
  });

  test('missing payment intent never fabricates success', () async {
    final backend = InProcessMockClient();
    final gateway = ApiPaymentGateway(
      api: ApiClient(env: environment, client: backend),
    );

    await expectLater(gateway.status('pi_missing'), throwsA(anything));
    await expectLater(gateway.confirm('pi_missing'), throwsA(anything));
  });
}
