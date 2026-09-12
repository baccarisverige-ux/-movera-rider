import 'package:movera_rider/features/payments/data/local_payment_repository.dart';
import 'package:movera_rider/features/payments/domain/payment_repository.dart';

class PaymentsRepository {
  PaymentsRepository({LocalPaymentRepository? store})
      : _store = store ?? LocalPaymentRepository();
  final LocalPaymentRepository _store;

  Future<List<PaymentMethod>> listMethods() => _store.listMethods();
  Future<void> setDefault(String methodId) => _store.setDefault(methodId);
  String get defaultId => _store.defaultId;
}
