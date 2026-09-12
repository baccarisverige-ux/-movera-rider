class FeatureFlags {
  const FeatureFlags({
    this.wallet = true,
    this.scheduledRides = true,
    this.promotions = true,
    this.safetyShareTrip = true,
    this.bookingLater = true,
  });

  final bool wallet;
  final bool scheduledRides;
  final bool promotions;
  final bool safetyShareTrip;
  final bool bookingLater;

  static const current = FeatureFlags();
}
