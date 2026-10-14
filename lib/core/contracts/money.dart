/// Money as the P1 contract carries it: integer minor units (öre) plus an
/// ISO-4217 currency code (ARCH-11, contract C-0).
///
/// Arithmetic and comparison stay in minor units. Whole-kronor doubles exist
/// only at the UI edge ([major]) and for legacy wire fields
/// ([Money.fromLegacyMajor]); new code must not round-trip through them.
class Money {
  const Money(this.amountMinor, [this.currency = defaultCurrency]);

  static const defaultCurrency = 'SEK';

  final int amountMinor;
  final String currency;

  static const zeroSek = Money(0);

  /// A legacy whole-unit amount (`price: 259.0`) converted once, here.
  factory Money.fromLegacyMajor(
    num major, [
    String currency = defaultCurrency,
  ]) => Money(
    (major * 100).round(),
    normalizeCurrency(currency) ?? defaultCurrency,
  );

  /// Parses `{amountMinor, currency}`. Returns null for anything else,
  /// including a currency that is not a three-letter ISO-4217 code.
  static Money? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final minor = raw['amountMinor'];
    if (minor is! num || minor != minor.roundToDouble()) return null;
    final currency = normalizeCurrency(raw['currency']);
    if (currency == null) return null;
    return Money(minor.toInt(), currency);
  }

  /// An integer minor-units field (`totalMinor: 25900`) in [currency].
  static Money? tryMinor(Object? raw, [Object? currency]) {
    if (raw is! num || raw != raw.roundToDouble()) return null;
    final code = currency == null
        ? defaultCurrency
        : normalizeCurrency(currency);
    if (code == null) return null;
    return Money(raw.toInt(), code);
  }

  /// A legacy whole-unit field (`newPriceKr: 259.5`), when present.
  static Money? tryLegacyMajor(
    Object? raw, [
    String currency = defaultCurrency,
  ]) => raw is num ? Money.fromLegacyMajor(raw, currency) : null;

  /// Upper-cased ISO-4217 alpha code, or null when [raw] is not one.
  static String? normalizeCurrency(Object? raw) {
    if (raw is! String) return null;
    final code = raw.trim().toUpperCase();
    return RegExp(r'^[A-Z]{3}$').hasMatch(code) ? code : null;
  }

  /// Whole units for display only (`259.0` kr).
  double get major => amountMinor / 100;

  bool get isPositive => amountMinor > 0;

  Money operator +(Money other) {
    _sameCurrency(other);
    return Money(amountMinor + other.amountMinor, currency);
  }

  Money operator -(Money other) {
    _sameCurrency(other);
    return Money(amountMinor - other.amountMinor, currency);
  }

  void _sameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('Cannot combine $currency and ${other.currency}.');
    }
  }

  Map<String, Object> toJson() => {
    'amountMinor': amountMinor,
    'currency': currency,
  };

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.amountMinor == amountMinor &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(amountMinor, currency);

  @override
  String toString() => 'Money($amountMinor $currency)';
}
