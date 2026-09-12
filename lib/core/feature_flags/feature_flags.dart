class FeatureFlags {
  const FeatureFlags({
    this.enableCash = true,
    this.enableApplePay = true,
    this.enableGooglePay = true,
    this.enableSwish = true,
    this.enableScheduledRide = true,
    this.enableLuxury = true,
    this.enablePromotions = true,
    this.enableWallet = true,
    this.enableRidePin = false,
    this.enableSafetyShareTrip = true,
    this.enableBookingLater = true,
  });

  final bool enableCash;
  final bool enableApplePay;
  final bool enableGooglePay;
  final bool enableSwish;
  final bool enableScheduledRide;
  final bool enableLuxury;
  final bool enablePromotions;
  final bool enableWallet;
  final bool enableRidePin;
  final bool enableSafetyShareTrip;
  final bool enableBookingLater;

  bool get wallet => enableWallet;
  bool get scheduledRides => enableScheduledRide;
  bool get promotions => enablePromotions;
  bool get safetyShareTrip => enableSafetyShareTrip;
  bool get bookingLater => enableBookingLater;

  static const current = FeatureFlags();
}
