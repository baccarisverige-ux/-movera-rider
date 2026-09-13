/// Configurable Movera scheduled-ride terms. Numeric legal values stay
/// unset until product/legal approves them. UI must read from this model.
class ReservationPolicy {
  const ReservationPolicy({
    required this.version,
    this.freeCancellationMinutes,
    this.cancellationFee,
    this.includedWaitMinutes,
    this.minimumAdvanceBookingMinutes,
    required this.pricingDisclaimer,
    required this.assignmentDisclaimer,
    required this.waitingSummary,
    required this.cancellationSummary,
    required this.pricingSummary,
    this.changeCharge,
    this.changeChargeSummary = 'No additional change charge',
    this.sections = const [],
  });

  final String version;
  final int? freeCancellationMinutes;
  final String? cancellationFee;
  final int? includedWaitMinutes;
  final int? minimumAdvanceBookingMinutes;
  final String pricingDisclaimer;
  final String assignmentDisclaimer;
  final String waitingSummary;
  final String cancellationSummary;
  final String pricingSummary;
  final String? changeCharge;
  final String changeChargeSummary;
  final List<ReservationPolicySection> sections;
}

class ReservationPolicySection {
  const ReservationPolicySection({required this.title, required this.body});

  final String title;
  final String body;
}
