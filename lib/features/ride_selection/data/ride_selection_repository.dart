import 'package:movera_rider/features/ride_selection/domain/ride_selection.dart';

class RideSelectionRepository {
  List<RideCatalogItem> rides() => const [
        RideCatalogItem(
          id: 'movera',
          image: 'assets/images/rides/movera.png',
          name: 'Movera',
          note: 'Affordable and convenient rides',
          arrival: '8 min',
          etaMin: 8,
          price: 259,
          seats: 4,
          badge: 'RECOMMENDED',
        ),
        RideCatalogItem(
          id: 'comfort',
          image: 'assets/images/rides/comfort.png',
          name: 'Comfort',
          note: 'Newer cars with extra legroom',
          arrival: '11 min',
          etaMin: 11,
          price: 339,
          seats: 4,
        ),
        RideCatalogItem(
          id: 'premium',
          image: 'assets/images/rides/premium.png',
          name: 'Premium',
          note: 'Premium cars with top-rated drivers',
          arrival: '11 min',
          etaMin: 11,
          price: 369,
          seats: 4,
        ),
        RideCatalogItem(
          id: 'priority',
          image: 'assets/images/rides/priority.png',
          name: 'Priority',
          note: 'More options, less waiting',
          arrival: '6 min',
          etaMin: 6,
          price: 289,
          seats: 4,
          badge: 'FASTER',
        ),
        RideCatalogItem(
          id: 'xl',
          image: 'assets/images/rides/xl.png',
          name: 'Movera XL',
          note: 'Cars for larger groups (6 people)',
          arrival: '12 min',
          etaMin: 12,
          price: 399,
          seats: 6,
        ),
        RideCatalogItem(
          id: 'electric',
          image: 'assets/images/rides/electric.png',
          name: 'Electric',
          note: 'Quiet and fossil-free cars',
          arrival: '9 min',
          etaMin: 9,
          price: 259,
          seats: 4,
          glyph: 'bolt',
        ),
        RideCatalogItem(
          id: 'pet',
          image: 'assets/images/rides/pet.png',
          name: 'Movera Pet',
          note: 'Pet-friendly rides',
          arrival: '10 min',
          etaMin: 10,
          price: 279,
          seats: 4,
          glyph: 'pets',
        ),
      ];

  List<RidePaymentItem> payments() => const [
        RidePaymentItem(
          brand: 'wallet',
          name: 'Movera Wallet',
          detail: 'Pay from your balance',
        ),
        RidePaymentItem(
          brand: 'apple',
          name: 'Apple Pay',
          detail: 'Available by default',
        ),
        RidePaymentItem(
          brand: 'google',
          name: 'Google Pay',
          detail: 'Available by default',
        ),
        RidePaymentItem(
          brand: 'paypal',
          name: 'PayPal',
          detail: 'Pay for this ride',
        ),
        RidePaymentItem(
          brand: 'cards',
          name: 'Card',
          detail: 'Visa, Mastercard',
        ),
        RidePaymentItem(
          brand: 'swish',
          name: 'Swish',
          detail: 'Instant mobile payment',
        ),
        RidePaymentItem(
          brand: 'cash',
          name: 'Cash',
          detail: 'Pay the driver in cash',
        ),
      ];
}
