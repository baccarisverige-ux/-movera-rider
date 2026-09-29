import 'package:movera_rider/features/payments/domain/payment_status.dart';
import 'package:movera_rider/features/ratings/domain/rating_status.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/trips/domain/trip_status.dart';

extension RideStatusContractProjection on RideStatus {
  TripStatus get tripStatus {
    switch (this) {
      case RideStatus.idle:
      case RideStatus.pickupSelected:
      case RideStatus.destinationSelected:
        return TripStatus.draft;
      case RideStatus.quoteLoading:
      case RideStatus.rideOptionsReady:
      case RideStatus.rideSelected:
      case RideStatus.paymentSelected:
        return TripStatus.quoted;
      case RideStatus.bookingRequested:
        return TripStatus.requested;
      case RideStatus.findingDriver:
      case RideStatus.searchDelayed:
        return TripStatus.searching;
      case RideStatus.driverAssigned:
        return TripStatus.accepted;
      case RideStatus.driverArriving:
        return TripStatus.driverToPickup;
      case RideStatus.driverWaiting:
        return TripStatus.arrived;
      case RideStatus.tripStarted:
        return TripStatus.riderOnboard;
      case RideStatus.tripInProgress:
        return TripStatus.inTrip;
      case RideStatus.approachingDropoff:
        return TripStatus.approachingDropoff;
      case RideStatus.tripCompleted:
      case RideStatus.paymentProcessing:
      case RideStatus.paymentFinalized:
      case RideStatus.ratingPending:
      case RideStatus.closed:
      case RideStatus.paymentFailed:
        return TripStatus.completed;
      case RideStatus.cancelledByRider:
        return TripStatus.cancelledByRider;
      case RideStatus.cancelledByDriver:
        return TripStatus.cancelledByDriver;
      case RideStatus.cancelledBySystem:
        return TripStatus.cancelledByAdmin;
      case RideStatus.noDriverFound:
      case RideStatus.bookingExpired:
        return TripStatus.expired;
    }
  }

  PaymentStatus get paymentStatus {
    switch (this) {
      case RideStatus.paymentProcessing:
        return PaymentStatus.processing;
      case RideStatus.paymentFinalized:
      case RideStatus.ratingPending:
      case RideStatus.closed:
        return PaymentStatus.succeeded;
      case RideStatus.paymentFailed:
        return PaymentStatus.failed;
      default:
        return PaymentStatus.notStarted;
    }
  }

  RatingStatus get ratingStatus {
    switch (this) {
      case RideStatus.ratingPending:
        return RatingStatus.pending;
      case RideStatus.closed:
        return RatingStatus.skipped;
      default:
        return RatingStatus.notRequested;
    }
  }
}
