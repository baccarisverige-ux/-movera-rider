/// The rider's active promotion, as the server sends it.
///
/// Promotions are created in the admin panel. The app never invents one: when
/// the server has nothing for this rider there is no [RiderPromotion] and the
/// ticket stays hidden.
class RiderPromotion {
  const RiderPromotion({
    required this.id,
    required this.title,
    required this.percentOff,
    required this.ridesLeft,
    required this.ridesTotal,
    this.endsAt,
    this.maxDiscountMinor,
    this.rideTypes = const [],
    this.rules = const [],
  });

  final String id;
  final String title;
  final int percentOff;
  final int ridesLeft;
  final int ridesTotal;
  final DateTime? endsAt;
  final int? maxDiscountMinor;

  /// Ride category ids the promotion applies to. Empty means every category.
  final List<String> rideTypes;
  final List<String> rules;

  /// Whether a ride of category [rideId] gets this promotion's discount.
  bool appliesTo(String rideId) =>
      rideTypes.isEmpty || rideTypes.contains(rideId);

  bool isActiveAt(DateTime now) =>
      ridesLeft > 0 && (endsAt == null || now.isBefore(endsAt!));

  static RiderPromotion? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final title = json['title'];
    final percent = json['percentOff'];
    final left = json['ridesLeft'];
    final total = json['ridesTotal'];
    if (id is! String || title is! String || title.trim().isEmpty) return null;
    if (percent is! num || left is! num) return null;
    final ends = json['endsAt'];
    final max = json['maxDiscountMinor'];
    final rules = json['rules'];
    final rideTypes = json['rideTypes'];
    return RiderPromotion(
      id: id,
      title: title.trim(),
      percentOff: percent.toInt(),
      ridesLeft: left.toInt(),
      ridesTotal: total is num ? total.toInt() : left.toInt(),
      endsAt: ends is String ? DateTime.tryParse(ends) : null,
      maxDiscountMinor: max is num ? max.toInt() : null,
      rideTypes: rideTypes is List
          ? rideTypes.whereType<String>().toList()
          : const [],
      rules: rules is List ? rules.whereType<String>().toList() : const [],
    );
  }
}
