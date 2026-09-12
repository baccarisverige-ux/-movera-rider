import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/wallet/data/wallet_repository.dart';
import 'package:movera_rider/features/wallet/domain/wallet_ledger.dart';

class WalletController {
  WalletController({WalletStore? store}) : _store = store ?? WalletStore();

  final WalletStore _store;

  Future<double> loadBalance() => _store.loadBalance();

  Future<void> setBalance({
    required double previous,
    required double next,
  }) async {
    await _store.saveBalance(next);
    final delta = next - previous;
    if (delta == 0) return;
    AppScope.instance.wallet.add(
      WalletEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        kind: delta > 0 ? WalletEntryKind.credit : WalletEntryKind.ride,
        amountMinor: (delta * 100).round(),
        at: DateTime.now(),
      ),
    );
  }
}
