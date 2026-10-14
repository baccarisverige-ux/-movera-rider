/// Book for later is switched off in this build (release until the server
/// reservation resource exists, ARCH-7 / contract C-8).
class ReservationsUnavailableException implements Exception {
  const ReservationsUnavailableException();

  @override
  String toString() =>
      'ReservationsUnavailableException(scheduling is not available)';
}

/// A scheduled ride needs the server's quote for its price (ARCH-16): the
/// rider is never booked at a catalog price the server did not quote.
class ScheduledQuoteRequiredException implements Exception {
  const ScheduledQuoteRequiredException(this.categoryId);

  final String categoryId;

  @override
  String toString() => 'ScheduledQuoteRequiredException($categoryId)';
}
