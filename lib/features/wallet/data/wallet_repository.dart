import 'package:movera_rider/core/storage/preferences_store.dart';

class WalletPaymentSettings {
  WalletPaymentSettings({
    required this.defaultMethod,
    required this.business,
    this.extraMethods = const [],
  });

  final String defaultMethod;
  final bool business;
  final List<Map<String, String>> extraMethods;
}

class WalletStore {
  static const balanceKey = 'movera_wallet_balance';
  static const _legacyVoucherKeys = [
    'movera_voucher_code',
    'movera_voucher_amount',
    'movera_voucher_expires',
    'movera_used_vouchers',
  ];

  Future<double> loadBalance() async {
    final prefs = await PreferencesStore.load();
    return prefs.getDouble(balanceKey) ?? 0;
  }

  Future<void> saveBalance(double value) async {
    final prefs = await PreferencesStore.load();
    await prefs.setDouble(balanceKey, value);
  }

  Future<WalletPaymentSettings> loadPayments() async {
    final prefs = await PreferencesStore.load();
    await _removeLegacyVoucherState(prefs);
    // Earlier builds stored unverified cards and provider labels locally.
    // None represent tokenized or authorized payment methods.
    if (prefs.containsKey('movera_payment_methods')) {
      await prefs.remove('movera_payment_methods');
    }
    final savedDefault = prefs.getString('movera_default_payment');
    final defaultMethod = savedDefault == 'paypal' ||
            savedDefault == 'klarna' ||
            savedDefault == 'card' ||
            (savedDefault?.startsWith('card_') ?? false)
        ? 'apple'
        : savedDefault ?? 'apple';
    if (savedDefault != defaultMethod) {
      await prefs.setString('movera_default_payment', defaultMethod);
    }
    return WalletPaymentSettings(
      defaultMethod: defaultMethod,
      business: prefs.getBool('movera_payment_business') ?? false,
    );
  }

  Future<void> savePayments(WalletPaymentSettings settings) async {
    final prefs = await PreferencesStore.load();
    await _removeLegacyVoucherState(prefs);
    final method = settings.defaultMethod;
    await prefs.setString(
      'movera_default_payment',
      method == 'paypal' || method == 'klarna' || method == 'card' ||
              method.startsWith('card_')
          ? 'apple'
          : method,
    );
    await prefs.setBool('movera_payment_business', settings.business);
    await prefs.remove('movera_payment_methods');
  }

  Future<void> _removeLegacyVoucherState(dynamic prefs) async {
    for (final key in _legacyVoucherKeys) {
      await prefs.remove(key);
    }
  }
}
