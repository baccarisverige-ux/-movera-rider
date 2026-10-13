/// A card the rider saved on this device (demo). Only the brand, the last
/// four digits, the expiry and the name are kept; the full number is never
/// stored. When the payment partner is connected its vault holds the card
/// and this becomes a reference to it.
class SavedCard {
  const SavedCard({
    required this.id,
    required this.brand,
    required this.last4,
    required this.expMonth,
    required this.expYear,
    required this.holder,
  });

  final String id;

  /// 'visa' or 'mastercard'.
  final String brand;
  final String last4;
  final int expMonth;

  /// Four digits, e.g. 2028.
  final int expYear;
  final String holder;

  /// The payment-method brand used across ride selection: `card:<id>`.
  String get methodBrand => 'card:$id';

  /// "Visa •••• 4242".
  String get displayName => '${brandLabel(brand)} •••• $last4';

  /// "08/28".
  String get expiryLabel =>
      '${expMonth.toString().padLeft(2, '0')}/'
      '${(expYear % 100).toString().padLeft(2, '0')}';

  static String brandLabel(String brand) {
    switch (brand) {
      case 'visa':
        return 'Visa';
      case 'mastercard':
        return 'Mastercard';
      default:
        return 'Card';
    }
  }

  Map<String, Object> toJson() => {
    'id': id,
    'brand': brand,
    'last4': last4,
    'expMonth': expMonth,
    'expYear': expYear,
    'holder': holder,
  };

  static SavedCard? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final brand = raw['brand'];
    final last4 = raw['last4'];
    final expMonth = raw['expMonth'];
    final expYear = raw['expYear'];
    final holder = raw['holder'];
    if (id is! String ||
        brand is! String ||
        last4 is! String ||
        expMonth is! int ||
        expYear is! int ||
        holder is! String) {
      return null;
    }
    return SavedCard(
      id: id,
      brand: brand,
      last4: last4,
      expMonth: expMonth,
      expYear: expYear,
      holder: holder,
    );
  }
}
