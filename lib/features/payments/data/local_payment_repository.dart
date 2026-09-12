import 'package:movera_rider/features/payments/domain/payment_repository.dart';

class LocalPaymentRepository implements PaymentRepository {
  String _defaultId = 'apple';

  @override
  Future<List<PaymentMethod>> listMethods() async {
    return const [
      PaymentMethod(id: 'wallet', kind: PaymentMethodKind.wallet, label: 'Movera Wallet'),
      PaymentMethod(id: 'apple', kind: PaymentMethodKind.applePay, label: 'Apple Pay'),
      PaymentMethod(id: 'google', kind: PaymentMethodKind.googlePay, label: 'Google Pay'),
      PaymentMethod(id: 'card', kind: PaymentMethodKind.card, label: 'Card'),
      PaymentMethod(id: 'swish', kind: PaymentMethodKind.swish, label: 'Swish'),
      PaymentMethod(id: 'paypal', kind: PaymentMethodKind.paypal, label: 'PayPal'),
      PaymentMethod(id: 'klarna', kind: PaymentMethodKind.klarna, label: 'Klarna'),
      PaymentMethod(id: 'cash', kind: PaymentMethodKind.cash, label: 'Cash'),
    ];
  }

  @override
  Future<void> setDefault(String methodId) async {
    _defaultId = methodId;
  }

  String get defaultId => _defaultId;
}
