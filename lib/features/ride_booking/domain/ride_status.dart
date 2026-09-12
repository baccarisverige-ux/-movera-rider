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
}
