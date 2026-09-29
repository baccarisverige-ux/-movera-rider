import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';

void main() {
  test('booking availability requires a fresh signed authoritative fare', () {
    final controller = RideSelectionController();
    final expiry = DateTime.now().add(const Duration(minutes: 5));
    controller.authoritativeQuotes['movera'] = RideQuote(
      id: 'q-41',
      rideType: 'movera',
      totalMinor: 12500,
      currency: 'SEK',
      expiresAt: expiry,
      signedPayload: 'signed-q-41',
    );
    controller.quoteIds['movera'] = 'q-41';
    controller.quoteExpiresAt['movera'] = expiry;
    controller.offeredPrices['movera'] = 125;

    expect(controller.quoteIsAvailable('movera'), isTrue);
    expect(controller.authoritativePriceFor('movera'), 125);

    // Any rider-visible amount that no longer equals the signed quote must
    // invalidate booking authority rather than silently submit another fare.
    controller.offeredPrices['movera'] = 124;
    expect(controller.quoteIsAvailable('movera'), isFalse);
    expect(controller.authoritativePriceFor('movera'), isNull);

    controller.dispose();
  });

  test('unsigned or wrong-category quotes cannot authorize booking', () {
    final controller = RideSelectionController();
    final expiry = DateTime.now().add(const Duration(minutes: 5));
    controller.authoritativeQuotes['movera'] = RideQuote(
      id: 'q-unsigned',
      rideType: 'premium',
      totalMinor: 12500,
      currency: 'SEK',
      expiresAt: expiry,
    );
    controller.quoteIds['movera'] = 'q-unsigned';
    controller.quoteExpiresAt['movera'] = expiry;
    controller.offeredPrices['movera'] = 125;

    expect(controller.quoteIsAvailable('movera'), isFalse);
    controller.dispose();
  });
}
