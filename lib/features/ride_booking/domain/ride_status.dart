/// Canonical ride lifecycle. The backend owns transitions;
/// the app only renders the current state.
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
  paymentFinalized,
  ratingPending,
  closed,
}
