import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_booking/data/catalog_quote_repository.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/features/ride_selection/data/ride_selection_repository.dart';

void main() {
  RideSelectionController controller() => RideSelectionController(
    store: RideSelectionRepository(),
    quotes: CatalogQuoteRepository(),
  );

  test('fresh quote remains authoritative before expiry', () {
    final selection = controller();
    final now = DateTime(2026, 9, 16, 10);
    selection.offeredPrices['movera'] = 249;
    selection.quoteIds['movera'] = 'q-fresh';
    selection.quoteExpiresAt['movera'] = now.add(const Duration(seconds: 30));

    expect(selection.priceFor('movera', 259, now: now), 249);
    expect(selection.quoteIdFor('movera', now: now), 'q-fresh');
    expect(selection.quoteIsFresh('movera', now: now), isTrue);
  });

  test('expired quote is discarded instead of showing or submitting stale fare', () {
    final selection = controller();
    final now = DateTime(2026, 9, 16, 10);
    selection.offeredPrices['movera'] = 199;
    selection.quoteIds['movera'] = 'q-expired';
    selection.quoteExpiresAt['movera'] = now.subtract(const Duration(seconds: 1));

    expect(selection.priceFor('movera', 259, now: now), 259);
    expect(selection.offeredPrices.containsKey('movera'), isFalse);
    expect(selection.quoteIdFor('movera', now: now), isNull);
    expect(selection.quoteExpiresAt.containsKey('movera'), isFalse);
  });

  test('catalog selection without a server quote is not authoritative', () {
    final selection = controller();
    selection.selectRide('xl', 399);

    expect(selection.priceFor('xl', 399), 399);
    expect(selection.quoteIsFresh('xl'), isFalse);
    expect(selection.quoteIsAvailable('xl'), isFalse);
  });
}
