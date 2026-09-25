import 'dart:convert';

import 'package:movera_rider/core/storage/preferences_store.dart';
import 'package:movera_rider/core/logging/app_log.dart';

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
    final savedMethods = prefs.getString('movera_payment_methods');
    var extra = <Map<String, String>>[];
    if (savedMethods != null) {
      try {
        final decoded = jsonDecode(savedMethods) as List<dynamic>;
        extra = decoded
            .whereType<Map>()
            .map(
              (item) => item.map(
                (key, value) => MapEntry(key.toString(), value.toString()),
              ),
            )
            .toList();
      } catch (error, stackTrace) {
        AppLog.error(
          'wallet.payment_methods_decode_failed',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    return WalletPaymentSettings(
      defaultMethod: prefs.getString('movera_default_payment') ?? 'apple',
      business: prefs.getBool('movera_payment_business') ?? false,
      extraMethods: extra,
    );
  }

  Future<void> savePayments(WalletPaymentSettings settings) async {
    final prefs = await PreferencesStore.load();
    await _removeLegacyVoucherState(prefs);
    await prefs.setString('movera_default_payment', settings.defaultMethod);
    await prefs.setBool('movera_payment_business', settings.business);
    await prefs.setString(
      'movera_payment_methods',
      jsonEncode(settings.extraMethods),
    );
  }

  Future<void> _removeLegacyVoucherState(dynamic prefs) async {
    for (final key in _legacyVoucherKeys) {
      await prefs.remove(key);
    }
  }
}
