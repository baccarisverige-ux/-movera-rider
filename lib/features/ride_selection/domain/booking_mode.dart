/// Shared booking context for the one Movera category selector.
///
/// Book now and Book for later use the same ride cards. Only the next
/// action changes: now enters Finding Driver, scheduled creates a
/// reservation and never starts a live search.
enum BookingMode { now, scheduled }

extension BookingModeBehavior on BookingMode {
  bool get entersFindingDriver => this == BookingMode.now;

  bool get createsReservation => this == BookingMode.scheduled;

  String get ctaVerb => this == BookingMode.scheduled ? 'Schedule' : 'Select';
}
