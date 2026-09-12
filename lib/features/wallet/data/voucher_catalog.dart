import 'dart:convert';

import 'package:movera_rider/core/storage/preferences_store.dart';

class VoucherOffer {
  const VoucherOffer({
    required this.code,
    required this.amountKr,
    required this.expires,
  });

  final String code;
  final int amountKr;
  final DateTime expires;

  bool get expired {
    final end = DateTime(expires.year, expires.month, expires.day, 23, 59, 59);
    return DateTime.now().isAfter(end);
  }
}

class VoucherCatalog {
  static const known = <String, (int, String)>{
    'MOVERA100': (100, '2026-12-31'),
    'WELCOME50': (50, '2026-12-31'),
    'RIDE200': (200, '2027-06-30'),
    'MOVE25': (25, '2026-11-30'),
    'SUMMER75': (75, '2026-08-01'),
  };

  VoucherOffer? lookup(String raw) {
    final code = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (code.length < 4) return null;
    final hit = known[code];
    if (hit != null) {
      return VoucherOffer(
        code: code,
        amountKr: hit.$1,
        expires: DateTime.parse(hit.$2),
      );
    }
    final stamped = RegExp(r'^KR(\d{2,4})-(\d{8})$').firstMatch(code);
    if (stamped != null) {
      final stamp = stamped.group(2)!;
      return VoucherOffer(
        code: code,
        amountKr: int.parse(stamped.group(1)!),
        expires: DateTime.parse(
          '${stamp.substring(0, 4)}-${stamp.substring(4, 6)}-${stamp.substring(6, 8)}',
        ),
      );
    }
    return null;
  }

  Future<Set<String>> usedCodes() async {
    final prefs = await PreferencesStore.load();
    final raw = prefs.getString('movera_used_vouchers');
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((item) => item.toString())
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> markUsed(String code) async {
    final prefs = await PreferencesStore.load();
    final used = await usedCodes();
    used.add(code);
    await prefs.setString('movera_used_vouchers', jsonEncode(used.toList()));
  }
}
