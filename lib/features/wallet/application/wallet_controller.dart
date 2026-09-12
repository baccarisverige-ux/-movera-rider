import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/features/wallet/data/wallet_repository.dart';
import 'package:movera_rider/features/wallet/domain/wallet_ledger.dart';

class WalletController {
  WalletController({WalletStore? store}) : _store = store ?? WalletStore();

  final WalletStore _store;

  Future<String?> loadVoucherCode() => _store.loadVoucherCode();

  Future<void> saveVoucher({
    required String code,
    required int amountKr,
    required DateTime expires,
  }) {
    return _store.saveVoucher(
      code: code,
      amountKr: amountKr,
      expires: expires,
    );
  }

  Future<WalletPaymentSettings> loadPayments() => _store.loadPayments();

  Future<void> savePayments(WalletPaymentSettings settings) =>
      _store.savePayments(settings);

  Future<double> loadBalance() => _store.loadBalance();

  Future<void> setBalance({
    required double previous,
    required double next,
  }) async {
    final delta = next - previous;
    if (delta > 0) {
      try {
        final intent = await AppScope.instance.paymentGateway.create(
          amountMinor: (delta * 100).round(),
          currency: 'SEK',
          idempotencyKey: newIdempotencyKey('wallet'),
        );
        final status = await AppScope.instance.paymentGateway.confirm(intent.id);
        if (status != 'succeeded') return;
        Analytics.track('payment_succeeded', extra: {'intent': intent.id});
      } catch (error, stack) {
        Analytics.paymentFailed();
        AppScope.instance.crashes.record(
          error,
          stack,
          operation: 'wallet.topup',
        );
        return;
      }
    }
    await _store.saveBalance(next);
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
