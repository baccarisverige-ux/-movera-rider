class Promotion {
  const Promotion({
    required this.id,
    required this.title,
    required this.discountType,
    required this.amount,
    required this.startsAt,
    required this.endsAt,
    this.maxDiscountMinor,
    this.minFareMinor = 0,
    this.rideTypes = const [],
    this.maxUses,
    this.active = true,
  });

  final String id;
  final String title;
  final String discountType;
  final double amount;
  final DateTime startsAt;
  final DateTime endsAt;
  final int? maxDiscountMinor;
  final int minFareMinor;
  final List<String> rideTypes;
  final int? maxUses;
  final bool active;

  bool get expired => DateTime.now().isAfter(endsAt);
}
