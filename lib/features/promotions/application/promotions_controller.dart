import 'package:flutter/foundation.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/feature_flags/feature_flags.dart';
import 'package:movera_rider/features/promotions/data/promotions_repository.dart';
import 'package:movera_rider/features/promotions/domain/promotion.dart';

/// The rider's promotions: what they have, the code they unlock, which one a
/// fare uses, and the popup Movera wants shown once.
class PromotionsController extends ChangeNotifier {
  PromotionsController({
    PromotionsRepository? repository,
    PromotionsStore? store,
    FeatureFlags? flags,
    DateTime Function()? now,
  })  : _repository = repository,
        _store = store ?? PromotionsStore(),
        _flags = flags,
        _now = now ?? DateTime.now;

  PromotionsRepository? _repository;
  final PromotionsStore _store;
  FeatureFlags? _flags;
  final DateTime Function() _now;

  PromotionsRepository get _repo =>
      _repository ??= ApiPromotionsRepository(api: AppScope.instance.api);
  FeatureFlags get _featureFlags => _flags ??= AppScope.instance.flags;

  List<Promotion> _all = const [];
  Set<String> _popupsSeen = const {};
  bool _loaded = false;
  bool loading = false;
  Object? error;

  bool get enabled => _featureFlags.enablePromotions;
  bool get loaded => _loaded;

  /// Promotions that can be used right now.
  List<Promotion> get live {
    final now = _now();
    return _all.where((item) => item.isLive(now)).toList();
  }

  List<Promotion> get all => List.unmodifiable(_all);

  /// Reads what the phone remembers, then asks Movera. Safe to call again.
  Future<void> load() async {
    if (!enabled) return;
    if (!_loaded) {
      _all = await _store.loadCached();
      _popupsSeen = await _store.popupsSeen();
      _loaded = true;
      notifyListeners();
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      _all = await _repo.list();
      await _store.saveCached(_all);
    } catch (fault) {
      error = fault;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Unlocks a code. Throws [RedeemException] with the reason when it cannot.
  Future<Promotion> redeem(String code) async {
    final normalized = normalizePromoCode(code);
    if (normalized.isEmpty) throw const RedeemException(RedeemFailure.unknownCode);
    if (_all.any((item) => item.code == normalized)) {
      throw const RedeemException(RedeemFailure.alreadyUsed);
    }
    final promotion = await _repo.redeem(normalized);
    _all = [promotion, ..._all.where((item) => item.id != promotion.id)];
    await _store.saveCached(_all);
    notifyListeners();
    return promotion;
  }

  /// The promotion that takes the most off this fare, or null.
  Promotion? bestFor({required String rideType, required int fareMinor}) {
    Promotion? best;
    var bestDiscount = 0;
    for (final item in live) {
      final discount = item.discountFor(rideType: rideType, fareMinor: fareMinor);
      if (discount > bestDiscount) {
        best = item;
        bestDiscount = discount;
      }
    }
    return best;
  }

  /// The code sent with quotes so Movera prices the ride with the promotion.
  /// Null when the rider has none that is live.
  String? get appliedCode {
    if (!enabled) return null;
    final list = live;
    if (list.isEmpty) return null;
    // Percent promotions with the highest value first; the backend applies the real rule.
    list.sort((a, b) => b.value.compareTo(a.value));
    return list.first.code;
  }

  /// The popup to show on open, if any: a live promotion marked popup that the
  /// rider has not closed yet.
  Promotion? popupToShow() {
    if (!enabled || !_featureFlags.enablePromoPopup) return null;
    for (final item in live) {
      if (item.popup && !_popupsSeen.contains(item.id)) return item;
    }
    return null;
  }

  Future<void> markPopupSeen(Promotion promotion) async {
    _popupsSeen = {..._popupsSeen, promotion.id};
    await _store.markPopupSeen(promotion.id);
    notifyListeners();
  }

  /// Promotions that have ended or are used up, newest end first.
  List<Promotion> get past {
    final now = _now();
    return _all.where((item) => !item.isLive(now)).toList()
      ..sort((a, b) => b.validTo.compareTo(a.validTo));
  }
}
