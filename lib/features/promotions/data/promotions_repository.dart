import 'dart:convert';

import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/api_error.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/storage/preferences_store.dart';
import 'package:movera_rider/features/promotions/domain/promotion.dart';

/// Thrown when a code cannot be used; the reason is for the rider.
class RedeemException implements Exception {
  const RedeemException(this.failure);
  final RedeemFailure failure;

  @override
  String toString() => 'RedeemException(${failure.name})';
}

abstract class PromotionsRepository {
  /// Promotions this rider can use now.
  Future<List<Promotion>> list();

  /// Unlocks a promotion with a code. Throws [RedeemException] when it cannot.
  Future<Promotion> redeem(String code);
}

/// Talks to `/api/v1/promotions`. The in-process mock answers in demo builds.
class ApiPromotionsRepository implements PromotionsRepository {
  ApiPromotionsRepository({required this.api});

  final ApiClient api;

  @override
  Future<List<Promotion>> list() async {
    final json = await api.get('/api/v1/promotions');
    final raw = json['promotions'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Promotion.fromJson(Map<String, dynamic>.from(item)))
        .whereType<Promotion>()
        .toList();
  }

  @override
  Future<Promotion> redeem(String code) async {
    try {
      final json = await api.post(
        '/api/v1/promotions/redeem',
        body: {'code': normalizePromoCode(code), 'apiVersion': 'v1'},
      );
      final raw = json['promotion'];
      final promotion = raw is Map ? Promotion.fromJson(Map<String, dynamic>.from(raw)) : null;
      if (promotion == null) throw const RedeemException(RedeemFailure.offline);
      return promotion;
    } on ApiError catch (error) {
      AppLog.error('promotion.redeem.refused', extra: {'code': error.code, 'status': error.statusCode});
      throw RedeemException(switch (error.code) {
        'PROMO_NOT_FOUND' => RedeemFailure.unknownCode,
        'PROMO_EXPIRED' => RedeemFailure.expired,
        'PROMO_ALREADY_USED' => RedeemFailure.alreadyUsed,
        'PROMO_NOT_FOR_RIDER' => RedeemFailure.notForYou,
        _ => RedeemFailure.offline,
      });
    }
  }
}

/// What the phone remembers between opens: the promotions last seen (so the
/// list shows at once) and which popups the rider has already closed.
class PromotionsStore {
  static const listKey = 'movera_promotions';
  static const popupsSeenKey = 'movera_promo_popups_seen';

  Future<List<Promotion>> loadCached() async {
    final prefs = await PreferencesStore.load();
    final raw = prefs.getString(listKey);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => Promotion.fromJson(Map<String, dynamic>.from(item)))
          .whereType<Promotion>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveCached(List<Promotion> list) async {
    final prefs = await PreferencesStore.load();
    await prefs.setString(listKey, jsonEncode(list.map((item) => item.toJson()).toList()));
  }

  Future<Set<String>> popupsSeen() async {
    final prefs = await PreferencesStore.load();
    return (prefs.getStringList(popupsSeenKey) ?? const []).toSet();
  }

  Future<void> markPopupSeen(String id) async {
    final prefs = await PreferencesStore.load();
    final seen = (prefs.getStringList(popupsSeenKey) ?? const []).toSet()..add(id);
    await prefs.setStringList(popupsSeenKey, seen.toList());
  }
}
