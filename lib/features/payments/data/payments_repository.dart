abstract class PaymentsRepository {
  Future<void> refresh();
}

class LocalPaymentsRepository implements PaymentsRepository {
  @override
  Future<void> refresh() async {}
}
