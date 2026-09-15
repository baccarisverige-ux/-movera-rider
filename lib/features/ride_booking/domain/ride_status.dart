/// Canonical ride lifecycle. Backend is the authority.
enum RideStatus {
  idle,
  pickupSelected,
  destinationSelected,
  quoteLoading,
  rideOptionsReady,
  rideSelected,
  paymentSelected,
  bookingRequested,
  findingDriver,
  searchDelayed,
  driverAssigned,
  driverArriving,
  driverWaiting,
  tripStarted,
  tripInProgress,
  tripCompleted,
  paymentProcessing,
  paymentFinalized,
  ratingPending,
  closed,
  cancelledByRider,
  cancelledByDriver,
  cancelledBySystem,
  noDriverFound,
  paymentFailed,
  bookingExpired,
}

extension RideStatusX on RideStatus {
  bool get isTerminal =>
      this == RideStatus.closed ||
      this == RideStatus.cancelledByRider ||
      this == RideStatus.cancelledByDriver ||
      this == RideStatus.cancelledBySystem ||
      this == RideStatus.noDriverFound ||
      this == RideStatus.paymentFailed ||
      this == RideStatus.bookingExpired;

  bool get isSearching =>
      this == RideStatus.bookingRequested ||
      this == RideStatus.findingDriver ||
      this == RideStatus.searchDelayed;

  bool get isMatched =>
      this == RideStatus.driverAssigned ||
      this == RideStatus.driverArriving ||
      this == RideStatus.driverWaiting ||
      this == RideStatus.tripStarted ||
      this == RideStatus.tripInProgress;

  /// Surfaces that show RideCompleted (live + restore).
  bool get isCompletedSurface =>
      this == RideStatus.tripCompleted ||
      this == RideStatus.paymentProcessing ||
      this == RideStatus.paymentFinalized ||
      this == RideStatus.ratingPending;
}
