
class PaymentIntent {
  const PaymentIntent({required this.id, required this.amountMinor, required this.currency});
  final String id;
  final int amountMinor;
  final String currency;
}

abstract class PaymentGateway {
  Future<PaymentIntent> create({required int amountMinor, required String currency, required String idempotencyKey});
  Future<String> confirm(String intentId);
  Future<String> status(String intentId);
}
