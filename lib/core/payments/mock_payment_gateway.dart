import 'package:movera_rider/core/payments/payment_gateway.dart';
import 'package:movera_rider/core/utils/request_id.dart';

class MockPaymentGateway implements PaymentGateway {
  final Map<String, PaymentIntent> _intents = {};

  @override
  Future<PaymentIntent> create({
    required int amountMinor,
    required String currency,
    required String idempotencyKey,
  }) async {
    final intent = PaymentIntent(
      id: 'pi_${newRequestId()}',
      amountMinor: amountMinor,
      currency: currency,
    );
    _intents[intent.id] = intent;
    return intent;
  }

  @override
  Future<String> confirm(String intentId) async => 'succeeded';

  @override
  Future<String> status(String intentId) async =>
      _intents.containsKey(intentId) ? 'succeeded' : 'not_found';
}
