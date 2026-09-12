import 'package:movera_rider/core/payments/payment_gateway.dart';
import 'package:movera_rider/core/utils/request_id.dart';

class MockPaymentGateway implements PaymentGateway {
  final Map<String, PaymentIntent> _intents = {};
  final Set<String> _usedKeys = {};
  bool failNext = false;

  @override
  Future<PaymentIntent> create({
    required int amountMinor,
    required String currency,
    required String idempotencyKey,
  }) async {
    if (failNext) {
      failNext = false;
      throw StateError('payment_failed');
    }
    if (_usedKeys.contains(idempotencyKey) && _intents.isNotEmpty) {
      return _intents.values.last;
    }
    _usedKeys.add(idempotencyKey);
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
