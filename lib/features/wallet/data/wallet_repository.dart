abstract class WalletRepository {
  Future<void> refresh();
}

class LocalWalletRepository implements WalletRepository {
  @override
  Future<void> refresh() async {}
}
