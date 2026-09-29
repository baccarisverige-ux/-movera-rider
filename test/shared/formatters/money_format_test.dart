import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/shared/formatters/money.dart';

/// Phase 132 cluster 1: currency formatting was reimplemented 5 times as
/// 'kr ${x.toStringAsFixed(0)}' (reservation_format.dart's price and kr,
/// select_ride.dart's _kr, wallet.dart's balance text, support.dart's
/// priceLabel). All 5 bodies were byte-identical, so consolidating onto
/// [formatKr] cannot change output — verified here against the old formula
/// for every call site's typical input.
void main() {
  String oldImplementation(num amount) => 'kr ${amount.toStringAsFixed(0)}';

  test('formatKr matches every duplicated call site for typical inputs', () {
    for (final amount in [0, 1, 99, 100.4, 100.5, 522, 1999.9, -25]) {
      expect(formatKr(amount), oldImplementation(amount));
    }
  });

  test('formatKr matches real call-site examples', () {
    expect(formatKr(522.0), 'kr 522'); // reservation price
    expect(formatKr(0), 'kr 0'); // wallet balance at zero
    expect(formatKr(149.0), 'kr 149'); // support ride price
  });

  test('formatSek (minor units) is unaffected by formatKr (major units)', () {
    expect(formatSek(10200), 'kr 102');
    expect(formatKr(102), 'kr 102');
  });
}
