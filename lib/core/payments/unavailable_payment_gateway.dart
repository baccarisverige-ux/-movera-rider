import 'package:movera_rider/core/payments/payment_gateway.dart';

class PaymentUnavailableException implements Exception {
  const PaymentUnavailableException(this.message);
  final String message;

  @override
  String toString() => 'PaymentUnavailableException($message)';
}

/// Explicit fail-closed fallback. Release composition rejects this placeholder
/// now that Phase 80 provides the authenticated backend payment transport.
class UnavailablePaymentGateway implements PaymentGateway {
  const UnavailablePaymentGateway();

  Never _unavailable() {
    throw const PaymentUnavailableException(
      'Payment processing is not available in this build.',
    );
  }

  @override
  Future<PaymentIntent> create({
    required int amountMinor,
    required String currency,
    required String idempotencyKey,
  }) async => _unavailable();

  @override
  Future<String> confirm(String intentId) async => _unavailable();

  @override
  Future<String> status(String intentId) async => _unavailable();
}
