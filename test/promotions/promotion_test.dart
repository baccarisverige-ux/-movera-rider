import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/promotions/domain/promotion.dart';

Promotion promo({
  PromotionKind kind = PromotionKind.percent,
  int value = 30,
  int maxPerRideMinor = 5000,
  int minFareMinor = 0,
  int ridesLeft = 3,
  List<String> categories = const [],
  DateTime? validTo,
}) {
  return Promotion(
    id: 'p1',
    code: 'WELCOME30',
    title: 'Welcome',
    kind: kind,
    value: value,
    maxPerRideMinor: maxPerRideMinor,
    minFareMinor: minFareMinor,
    ridesLeft: ridesLeft,
    validFrom: DateTime.utc(2026, 1, 1),
    validTo: validTo ?? DateTime.utc(2026, 12, 31),
    categories: categories,
  );
}

void main() {
  test('percent discount is capped per ride and never above the fare', () {
    expect(promo().discountFor(rideType: 'movera', fareMinor: 25900), 5000);
    expect(promo(maxPerRideMinor: 0).discountFor(rideType: 'movera', fareMinor: 25900), 7770);
    expect(promo(kind: PromotionKind.fixed, value: 4000).discountFor(rideType: 'movera', fareMinor: 3000), 3000);
  });

  test('a promotion only applies to its categories and above the lowest fare', () {
    final comfortOnly = promo(categories: ['comfort']);
    expect(comfortOnly.discountFor(rideType: 'movera', fareMinor: 25900), 0);
    expect(comfortOnly.discountFor(rideType: 'comfort', fareMinor: 25900), 5000);
    expect(promo(minFareMinor: 30000).discountFor(rideType: 'movera', fareMinor: 25900), 0);
  });

  test('live means rides left and inside the dates', () {
    final now = DateTime.utc(2026, 6, 1);
    expect(promo().isLive(now), isTrue);
    expect(promo(ridesLeft: 0).isLive(now), isFalse);
    expect(promo(validTo: DateTime.utc(2026, 5, 1)).isLive(now), isFalse);
    expect(promo().isLive(DateTime.utc(2025, 12, 31)), isFalse);
  });

  test('labels read like the admin panel', () {
    expect(promo().label, '30% off, up to kr 50');
    expect(promo(maxPerRideMinor: 0).label, '30% off');
    expect(promo(kind: PromotionKind.fixed, value: 4000).label, 'kr 40 off');
  });

  test('json round trip keeps every field and rejects broken rows', () {
    final back = Promotion.fromJson(promo(categories: ['comfort']).toJson());
    expect(back, isNotNull);
    expect(back!.code, 'WELCOME30');
    expect(back.categories, ['comfort']);
    expect(back.maxPerRideMinor, 5000);
    expect(Promotion.fromJson({'id': 'x'}), isNull);
  });

  test('movera://promo/CODE links give the code, other links nothing', () {
    expect(promoCodeFromLink('movera://promo/autumn15'), 'AUTUMN15');
    expect(promoCodeFromLink('movera://promo/AUTUMN-15?x=1'), 'AUTUMN15');
    expect(promoCodeFromLink('/promo/FLAT40'), 'FLAT40');
    expect(promoCodeFromLink('/'), isNull);
    expect(promoCodeFromLink('movera://ride/123'), isNull);
    expect(promoCodeFromLink('https://movera.se/promo/X'), isNull);
    expect(promoCodeFromLink(null), isNull);
    expect(normalizePromoCode(' welcome 30 '), 'WELCOME30');
  });
}
