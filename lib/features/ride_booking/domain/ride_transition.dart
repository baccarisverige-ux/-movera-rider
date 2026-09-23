import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

const _allowed = <RideStatus, Set<RideStatus>>{
  RideStatus.idle: {RideStatus.pickupSelected},
  RideStatus.pickupSelected: {RideStatus.destinationSelected, RideStatus.idle},
  RideStatus.destinationSelected: {
    RideStatus.quoteLoading,
    RideStatus.pickupSelected,
    RideStatus.idle,
  },
  RideStatus.quoteLoading: {
    RideStatus.rideOptionsReady,
    RideStatus.idle,
    RideStatus.bookingExpired,
  },
  RideStatus.rideOptionsReady: {
    RideStatus.rideSelected,
    RideStatus.quoteLoading,
    RideStatus.idle,
  },
  RideStatus.rideSelected: {
    RideStatus.paymentSelected,
    RideStatus.rideOptionsReady,
  },
  RideStatus.paymentSelected: {
    RideStatus.bookingRequested,
    RideStatus.rideSelected,
  },
  RideStatus.bookingRequested: {
    RideStatus.findingDriver,
    RideStatus.bookingExpired,
    RideStatus.cancelledByRider,
    RideStatus.cancelledBySystem,
  },
  RideStatus.findingDriver: {
    RideStatus.searchDelayed,
    RideStatus.driverAssigned,
    RideStatus.noDriverFound,
    RideStatus.cancelledByRider,
    RideStatus.cancelledBySystem,
  },
  RideStatus.searchDelayed: {
    RideStatus.findingDriver,
    RideStatus.driverAssigned,
    RideStatus.noDriverFound,
    RideStatus.cancelledByRider,
    RideStatus.cancelledBySystem,
  },
  RideStatus.driverAssigned: {
    RideStatus.driverArriving,
    RideStatus.cancelledByRider,
    RideStatus.cancelledByDriver,
    RideStatus.cancelledBySystem,
  },
  RideStatus.driverArriving: {
    RideStatus.driverWaiting,
    RideStatus.cancelledByRider,
    RideStatus.cancelledByDriver,
  },
  RideStatus.driverWaiting: {
    RideStatus.tripStarted,
    RideStatus.cancelledByRider,
    RideStatus.cancelledByDriver,
  },
  RideStatus.tripStarted: {
    RideStatus.tripInProgress,
    RideStatus.cancelledByRider,
  },
  RideStatus.tripInProgress: {
    // Backends that do not emit an explicit approach event may complete
    // directly; authoritative transports that do emit it can surface it first.
    RideStatus.approachingDropoff,
    RideStatus.tripCompleted,
    RideStatus.cancelledBySystem,
  },
  RideStatus.approachingDropoff: {
    RideStatus.tripCompleted,
    RideStatus.cancelledByRider,
    RideStatus.cancelledBySystem,
  },
  RideStatus.tripCompleted: {
    RideStatus.paymentProcessing,
    RideStatus.paymentFailed,
  },
  RideStatus.paymentProcessing: {
    RideStatus.paymentFinalized,
    RideStatus.paymentFailed,
  },
  RideStatus.paymentFinalized: {RideStatus.ratingPending},
  RideStatus.ratingPending: {RideStatus.closed},
};

class InvalidRideTransition implements Exception {
  InvalidRideTransition(this.from, this.to);
  final RideStatus from;
  final RideStatus to;
  @override
  String toString() => 'InvalidRideTransition($from → $to)';
}

RideStatus transitionRide(RideStatus from, RideStatus to) {
  if (!canTransition(from, to)) {
    throw InvalidRideTransition(from, to);
  }
  return to;
}

/// Client mutations must follow this graph. Backend projections may jump.
bool canTransition(RideStatus from, RideStatus to) {
  if (from.isTerminal) return false;
  final next = _allowed[from];
  return next != null && next.contains(to);
}
