import 'package:movera_rider/features/reservations/domain/reservation_status.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

/// Canonical trip lifecycle (P1). Payment and rating are separate machines.
///
/// [RideStatus] stays the Rider UI/session enum. Map through [tripStatus].
enum TripStatus {
  draft,
  quoted,
  requested,
  searching,
  offered,
  accepted,
  driverToPickup,
  arrived,
  riderOnboard,
  inTrip,
  approachingDropoff,
  completed,
  cancelledByRider,
  cancelledByDriver,
  cancelledByAdmin,
  noShow,
  expired,
  failed,
}

extension TripStatusWire on TripStatus {
  String get wireName => switch (this) {
        TripStatus.draft => 'draft',
        TripStatus.quoted => 'quoted',
        TripStatus.requested => 'requested',
        TripStatus.searching => 'searching',
        TripStatus.offered => 'offered',
        TripStatus.accepted => 'accepted',
        TripStatus.driverToPickup => 'driver_to_pickup',
        TripStatus.arrived => 'arrived',
        TripStatus.riderOnboard => 'rider_onboard',
        TripStatus.inTrip => 'in_trip',
        TripStatus.approachingDropoff => 'approaching_dropoff',
        TripStatus.completed => 'completed',
        TripStatus.cancelledByRider => 'cancelled_by_rider',
        TripStatus.cancelledByDriver => 'cancelled_by_driver',
        TripStatus.cancelledByAdmin => 'cancelled_by_admin',
        TripStatus.noShow => 'no_show',
        TripStatus.expired => 'expired',
        TripStatus.failed => 'failed',
      };
}

extension RideStatusAsTripStatus on RideStatus {
  TripStatus get tripStatus => switch (this) {
        RideStatus.idle ||
        RideStatus.pickupSelected ||
        RideStatus.destinationSelected =>
          TripStatus.draft,
        RideStatus.quoteLoading ||
        RideStatus.rideOptionsReady ||
        RideStatus.rideSelected ||
        RideStatus.paymentSelected =>
          TripStatus.quoted,
        RideStatus.bookingRequested => TripStatus.requested,
        RideStatus.findingDriver ||
        RideStatus.searchDelayed =>
          TripStatus.searching,
        RideStatus.driverAssigned => TripStatus.accepted,
        RideStatus.driverArriving => TripStatus.driverToPickup,
        RideStatus.driverWaiting => TripStatus.arrived,
        RideStatus.tripStarted => TripStatus.riderOnboard,
        RideStatus.tripInProgress => TripStatus.inTrip,
        RideStatus.tripCompleted ||
        RideStatus.paymentProcessing ||
        RideStatus.paymentFinalized ||
        RideStatus.ratingPending ||
        RideStatus.closed =>
          TripStatus.completed,
        RideStatus.cancelledByRider => TripStatus.cancelledByRider,
        RideStatus.cancelledByDriver => TripStatus.cancelledByDriver,
        RideStatus.cancelledBySystem => TripStatus.cancelledByAdmin,
        RideStatus.noDriverFound => TripStatus.expired,
        RideStatus.paymentFailed => TripStatus.failed,
        RideStatus.bookingExpired => TripStatus.expired,
      };
}

/// R3: ReservationStatus.driverEnRoute is RideStatus.driverArriving.
extension ReservationStatusAsTripStatus on ReservationStatus {
  TripStatus get tripStatus => switch (this) {
        ReservationStatus.scheduled => TripStatus.accepted,
        ReservationStatus.driverAssignmentPending => TripStatus.searching,
        ReservationStatus.driverAssigned => TripStatus.accepted,
        ReservationStatus.driverEnRoute => TripStatus.driverToPickup,
        ReservationStatus.driverArrived => TripStatus.arrived,
        ReservationStatus.inProgress => TripStatus.inTrip,
        ReservationStatus.completed => TripStatus.completed,
        ReservationStatus.cancelled => TripStatus.cancelledByRider,
      };

  RideStatus get asRideStatus => switch (this) {
        ReservationStatus.scheduled => RideStatus.rideSelected,
        ReservationStatus.driverAssignmentPending => RideStatus.findingDriver,
        ReservationStatus.driverAssigned => RideStatus.driverAssigned,
        ReservationStatus.driverEnRoute => RideStatus.driverArriving,
        ReservationStatus.driverArrived => RideStatus.driverWaiting,
        ReservationStatus.inProgress => RideStatus.tripInProgress,
        ReservationStatus.completed => RideStatus.tripCompleted,
        ReservationStatus.cancelled => RideStatus.cancelledByRider,
      };
}
