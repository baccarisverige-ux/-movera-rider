import 'package:movera_rider/features/payments/data/payments_repository.dart';
import 'package:movera_rider/features/payments/domain/payment_repository.dart';

class PaymentsController {
  PaymentsController({PaymentsRepository? store})
      : _store = store ?? PaymentsRepository();
  final PaymentsRepository _store;

  Future<List<PaymentMethod>> methods() => _store.listMethods();
  Future<void> setDefault(String id) => _store.setDefault(id);
  String get defaultId => _store.defaultId;
}
