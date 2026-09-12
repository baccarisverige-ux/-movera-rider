import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/features/wallet/data/voucher_catalog.dart';
import 'package:movera_rider/features/wallet/data/wallet_repository.dart';
import 'package:movera_rider/features/wallet/domain/wallet_ledger.dart';

export 'package:movera_rider/features/wallet/data/voucher_catalog.dart'
    show VoucherOffer;

class WalletController {
  WalletController({WalletStore? store, VoucherCatalog? vouchers})
      : _store = store ?? WalletStore(),
        _vouchers = vouchers ?? VoucherCatalog();

  final WalletStore _store;
  final VoucherCatalog _vouchers;
  final Set<String> _topUpKeys = {};

  VoucherOffer? lookup(String raw) => _vouchers.lookup(raw);

  Future<Set<String>> usedCodes() => _vouchers.usedCodes();

  Future<void> markUsed(String code) => _vouchers.markUsed(code);

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

  Future<double?> topUp({
    required double previous,
    required double amount,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? newIdempotencyKey('wallet');
    if (_topUpKeys.contains(key)) return previous;
    _topUpKeys.add(key);
    try {
      final intent = await AppScope.instance.paymentGateway.create(
        amountMinor: (amount * 100).round(),
        currency: 'SEK',
        idempotencyKey: key,
      );
      final status = await AppScope.instance.paymentGateway.confirm(intent.id);
      if (status != 'succeeded') return null;
      Analytics.track('payment_succeeded', extra: {'intent': intent.id});
    } catch (error, stack) {
      Analytics.paymentFailed();
      AppScope.instance.crashes.record(error, stack, operation: 'wallet.topup');
      return null;
    }
    final next = previous + amount;
    await _store.saveBalance(next);
    AppScope.instance.wallet.add(
      WalletEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        kind: WalletEntryKind.credit,
        amountMinor: (amount * 100).round(),
        at: DateTime.now(),
      ),
    );
    return next;
  }

  Future<double?> redeemVoucher({
    required double previous,
    required VoucherOffer offer,
  }) async {
    final used = await _vouchers.usedCodes();
    if (used.contains(offer.code.toUpperCase())) return previous;
    if (offer.expires.isBefore(DateTime.now())) return previous;
    await _vouchers.markUsed(offer.code);
    await saveVoucher(
      code: offer.code,
      amountKr: offer.amountKr,
      expires: offer.expires,
    );
    final next = previous + offer.amountKr;
    await _store.saveBalance(next);
    AppScope.instance.wallet.add(
      WalletEntry(
        id: 'voucher-${offer.code}',
        kind: WalletEntryKind.voucher,
        amountMinor: offer.amountKr * 100,
        at: DateTime.now(),
      ),
    );
    return next;
  }

  Future<double> chargeRide({
    required double previous,
    required double amount,
  }) async {
    final next = previous - amount;
    await _store.saveBalance(next);
    AppScope.instance.wallet.add(
      WalletEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        kind: WalletEntryKind.ride,
        amountMinor: -(amount * 100).round(),
        at: DateTime.now(),
      ),
    );
    return next;
  }

  Future<double> refund({
    required double previous,
    required double amount,
  }) async {
    final next = previous + amount;
    await _store.saveBalance(next);
    AppScope.instance.wallet.add(
      WalletEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        kind: WalletEntryKind.refund,
        amountMinor: (amount * 100).round(),
        at: DateTime.now(),
      ),
    );
    return next;
  }
}
