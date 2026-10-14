class FeatureFlags {
  const FeatureFlags({
    this.enableCash = true,
    this.enableApplePay = true,
    this.enableGooglePay = true,
    this.enableSwish = true,
    this.enableScheduledRide = true,
    this.enableLuxury = true,
    this.enableWallet = true,
    this.enableRidePin = false,
    this.enableSafetyShareTrip = true,
    this.enableBookingLater = true,
    this.enableBusinessProfile = false,
  });

  final bool enableCash;
  final bool enableApplePay;
  final bool enableGooglePay;
  final bool enableSwish;
  final bool enableScheduledRide;
  final bool enableLuxury;
  final bool enableWallet;
  final bool enableRidePin;
  final bool enableSafetyShareTrip;
  final bool enableBookingLater;

  /// FLOW-11: Personal/Business only becomes a choice once booking, history
  /// and receipts use it; until then the toggle is hidden.
  final bool enableBusinessProfile;

  bool get wallet => enableWallet;
  bool get scheduledRides => enableScheduledRide;
  bool get safetyShareTrip => enableSafetyShareTrip;
  bool get bookingLater => enableBookingLater;
  bool get businessProfile => enableBusinessProfile;

  static const current = FeatureFlags();
}
