import 'dart:convert';

import 'package:movera_rider/core/storage/preferences_store.dart';

class WalletPaymentSettings {
  WalletPaymentSettings({
    required this.defaultMethod,
    required this.business,
    this.voucherCode,
    this.extraMethods = const [],
  });

  final String defaultMethod;
  final bool business;
  final String? voucherCode;
  final List<Map<String, String>> extraMethods;
}

class WalletStore {
  static const balanceKey = 'movera_wallet_balance';

  Future<double> loadBalance() async {
    final prefs = await PreferencesStore.load();
    return prefs.getDouble(balanceKey) ?? 0;
  }

  Future<void> saveBalance(double value) async {
    final prefs = await PreferencesStore.load();
    await prefs.setDouble(balanceKey, value);
  }

  Future<String?> loadVoucherCode() async {
    final prefs = await PreferencesStore.load();
    return prefs.getString('movera_voucher_code');
  }

  Future<void> saveVoucher({
    required String code,
    required int amountKr,
    required DateTime expires,
  }) async {
    final prefs = await PreferencesStore.load();
    await prefs.setString('movera_voucher_code', code);
    await prefs.setInt('movera_voucher_amount', amountKr);
    await prefs.setString('movera_voucher_expires', expires.toIso8601String());
  }

  Future<WalletPaymentSettings> loadPayments() async {
    final prefs = await PreferencesStore.load();
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
      } catch (_) {}
    }
    return WalletPaymentSettings(
      defaultMethod: prefs.getString('movera_default_payment') ?? 'apple',
      business: prefs.getBool('movera_payment_business') ?? false,
      voucherCode: prefs.getString('movera_voucher_code'),
      extraMethods: extra,
    );
  }

  Future<void> savePayments(WalletPaymentSettings settings) async {
    final prefs = await PreferencesStore.load();
    await prefs.setString('movera_default_payment', settings.defaultMethod);
    await prefs.setBool('movera_payment_business', settings.business);
    await prefs.setString(
      'movera_payment_methods',
      jsonEncode(settings.extraMethods),
    );
    if (settings.voucherCode == null || settings.voucherCode!.isEmpty) {
      await prefs.remove('movera_voucher_code');
    } else {
      await prefs.setString('movera_voucher_code', settings.voucherCode!);
    }
  }
}
