import 'package:movera_rider/features/payments/domain/payment_status.dart';
import 'package:movera_rider/features/ratings/domain/rating_status.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

// ARCH-10: the RideStatus -> TripStatus map has one home, core/contracts.
// Re-exported so existing importers keep `status.tripStatus`.
export 'package:movera_rider/core/contracts/trip_status.dart'
    show RideStatusAsTripStatus;

extension RideStatusContractProjection on RideStatus {
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
