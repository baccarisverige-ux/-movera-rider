enum PaymentMethodKind {
  wallet,
  applePay,
  googlePay,
  card,
  swish,
  paypal,
  klarna,
  cash,
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.kind,
    required this.label,
    this.detail,
  });

  final String id;
  final PaymentMethodKind kind;
  final String label;
  final String? detail;
}

/// Money never flows through the UI. Implementations live in data/.
abstract class PaymentRepository {
  Future<List<PaymentMethod>> listMethods();
  Future<void> setDefault(String methodId);
}
