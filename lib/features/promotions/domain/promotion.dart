/// A promotion the rider can use: given to them by Movera, or unlocked with a code.
///
/// Mirrors the admin panel's promotion ticket: percent or fixed discount, the
/// most it takes off one ride, the lowest fare it applies to, the ride
/// categories it covers, and how many rides are left.
class Promotion {
  const Promotion({
    required this.id,
    required this.code,
    required this.title,
    required this.kind,
    required this.value,
    required this.maxPerRideMinor,
    required this.minFareMinor,
    required this.ridesLeft,
    required this.validFrom,
    required this.validTo,
    this.categories = const [],
    this.popup = false,
    this.message,
    this.image,
  });

  final String id;
  final String code;
  final String title;

  /// `percent`: [value] is a percentage. `fixed`: [value] is minor units off.
  final PromotionKind kind;
  final int value;
  final int maxPerRideMinor;
  final int minFareMinor;
  final int ridesLeft;
  final DateTime validFrom;
  final DateTime validTo;

  /// Ride categories it applies to. Empty means every category.
  final List<String> categories;

  /// Movera wants this shown once as a popup when the app opens.
  final bool popup;
  final String? message;
  final String? image;

  bool isLive(DateTime now) =>
      ridesLeft > 0 && !now.isBefore(validFrom) && now.isBefore(validTo);

  bool covers(String rideType) =>
      categories.isEmpty || categories.contains(rideType);

  /// What this promotion takes off a fare, in minor units. 0 when it does not apply.
  int discountFor({required String rideType, required int fareMinor}) {
    if (!covers(rideType) || fareMinor <= 0 || fareMinor < minFareMinor) return 0;
    final raw = kind == PromotionKind.percent
        ? (fareMinor * value / 100).round()
        : value;
    final capped = maxPerRideMinor > 0 ? raw.clamp(0, maxPerRideMinor) : raw;
    return capped.clamp(0, fareMinor);
  }

  /// Short text for a card: "30% off, up to kr 50" or "kr 40 off".
  String get label {
    if (kind == PromotionKind.percent) {
      final cap = maxPerRideMinor > 0 ? ', up to kr ${maxPerRideMinor ~/ 100}' : '';
      return '$value% off$cap';
    }
    return 'kr ${value ~/ 100} off';
  }

  static Promotion? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final code = json['code'];
    final from = DateTime.tryParse('${json['validFrom'] ?? ''}');
    final to = DateTime.tryParse('${json['validTo'] ?? ''}');
    if (id is! String || code is! String || from == null || to == null) return null;
    final rawCategories = json['categories'];
    return Promotion(
      id: id,
      code: code,
      title: '${json['title'] ?? code}',
      kind: json['kind'] == 'fixed' ? PromotionKind.fixed : PromotionKind.percent,
      value: (json['value'] as num?)?.round() ?? 0,
      maxPerRideMinor: (json['maxPerRideMinor'] as num?)?.round() ?? 0,
      minFareMinor: (json['minFareMinor'] as num?)?.round() ?? 0,
      ridesLeft: (json['ridesLeft'] as num?)?.round() ?? 0,
      validFrom: from,
      validTo: to,
      categories: rawCategories is List
          ? rawCategories.map((item) => '$item').toList()
          : const [],
      popup: json['popup'] == true,
      message: json['message'] as String?,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'title': title,
        'kind': kind == PromotionKind.percent ? 'percent' : 'fixed',
        'value': value,
        'maxPerRideMinor': maxPerRideMinor,
        'minFareMinor': minFareMinor,
        'ridesLeft': ridesLeft,
        'validFrom': validFrom.toIso8601String(),
        'validTo': validTo.toIso8601String(),
        'categories': categories,
        'popup': popup,
        if (message != null) 'message': message,
        if (image != null) 'image': image,
      };
}

enum PromotionKind { percent, fixed }

/// Why a code could not be used, in the rider's words.
enum RedeemFailure { unknownCode, expired, alreadyUsed, notForYou, offline }

extension RedeemFailureText on RedeemFailure {
  String get message => switch (this) {
        RedeemFailure.unknownCode => 'That code does not exist. Check the spelling and try again.',
        RedeemFailure.expired => 'That code has ended.',
        RedeemFailure.alreadyUsed => 'You already have this promotion.',
        RedeemFailure.notForYou => 'That code is not for this account.',
        RedeemFailure.offline => 'Movera could not check the code right now. Try again in a moment.',
      };
}

/// The code inside a `movera://promo/CODE` link, or null for any other link.
String? promoCodeFromLink(String? link) {
  if (link == null || link.isEmpty) return null;
  final uri = Uri.tryParse(link);
  if (uri == null) return null;
  final isScheme = uri.scheme == 'movera' && (uri.host == 'promo' || uri.pathSegments.firstOrNull == 'promo');
  final isPath = uri.scheme.isEmpty && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'promo';
  if (!isScheme && !isPath) return null;
  final segments = uri.host == 'promo' ? uri.pathSegments : uri.pathSegments.skip(1).toList();
  final code = segments.isNotEmpty ? segments.first : null;
  if (code == null || code.isEmpty) return null;
  return normalizePromoCode(code);
}

/// Codes are letters and digits, upper case, like the admin panel makes them.
String normalizePromoCode(String raw) =>
    raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
