import 'package:movera_rider/core/storage/preferences_store.dart';

/// The wallet balance's source of truth.
///
/// [WalletStore] is the only implementation today, and it is client-local
/// (a double in SharedPreferences/localStorage): anyone with access to the
/// device or browser storage can edit it, and it is never synced against
/// what a backend actually charged or refunded. A real implementation
/// backed by a server-owned ledger must replace it before a release
/// composition may treat the balance as authoritative — see
/// `WalletComposition.validate`.
abstract class WalletBalanceSource {
  Future<double> loadBalance();
  Future<void> saveBalance(double value);
}

class WalletPaymentSettings {
  WalletPaymentSettings({
    required this.defaultMethod,
    required this.business,
    this.extraMethods = const [],
    this.useWalletFirst = true,
  });

  final String defaultMethod;
  final bool business;
  final List<Map<String, String>> extraMethods;

  /// The wallet balance is taken off every fare first; the rest goes to
  /// the chosen method. On by default.
  final bool useWalletFirst;
}

class WalletStore implements WalletBalanceSource {
  static const balanceKey = 'movera_wallet_balance';
  static const _legacyVoucherKeys = [
    'movera_voucher_code',
    'movera_voucher_amount',
    'movera_voucher_expires',
    'movera_used_vouchers',
  ];

  @override
  Future<double> loadBalance() async {
    final prefs = await PreferencesStore.load();
    return prefs.getDouble(balanceKey) ?? 0;
  }

  @override
  Future<void> saveBalance(double value) async {
    final prefs = await PreferencesStore.load();
    await prefs.setDouble(balanceKey, value);
  }

  static const _removedMethods = {'paypal', 'klarna', 'swish'};

  Future<WalletPaymentSettings> loadPayments() async {
    final prefs = await PreferencesStore.load();
    await _removeLegacyVoucherState(prefs);
    // Earlier builds stored unverified cards and provider labels locally.
    // None represent tokenized or authorized payment methods.
    if (prefs.getString('movera_payment_methods') != null) {
      await prefs.remove('movera_payment_methods');
    }
    final savedDefault = prefs.getString('movera_default_payment');
    // Pay in car is the default; removed methods (PayPal, Klarna, Swish)
    // and unverified local cards fall back to it.
    final defaultMethod = savedDefault == null ||
            _removedMethods.contains(savedDefault) ||
            savedDefault == 'card' ||
            savedDefault.startsWith('card_')
        ? 'cash'
        : savedDefault;
    if (savedDefault != defaultMethod) {
      await prefs.setString('movera_default_payment', defaultMethod);
    }
    return WalletPaymentSettings(
      defaultMethod: defaultMethod,
      business: prefs.getBool('movera_payment_business') ?? false,
      useWalletFirst: prefs.getBool(walletFirstKey) ?? true,
    );
  }

  Future<void> savePayments(WalletPaymentSettings settings) async {
    final prefs = await PreferencesStore.load();
    await _removeLegacyVoucherState(prefs);
    final method = settings.defaultMethod;
    await prefs.setString(
      'movera_default_payment',
      _removedMethods.contains(method) || method == 'card' ||
              method.startsWith('card_')
          ? 'cash'
          : method,
    );
    await prefs.setBool('movera_payment_business', settings.business);
    await prefs.setBool(walletFirstKey, settings.useWalletFirst);
    await prefs.remove('movera_payment_methods');
  }

  static const walletFirstKey = 'movera_wallet_first';

  /// Demo flavour only: a rider with 50 kr in the wallet, so the split
  /// payment can be seen on GitHub Pages. A stored balance is never touched.
  static Future<void> seedDemoBalance({double kr = 50}) async {
    final prefs = await PreferencesStore.load();
    if (prefs.getDouble(balanceKey) != null) return;
    await prefs.setDouble(balanceKey, kr);
  }

  Future<void> _removeLegacyVoucherState(dynamic prefs) async {
    for (final key in _legacyVoucherKeys) {
      await prefs.remove(key);
    }
  }
}
