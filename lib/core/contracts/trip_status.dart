import 'package:movera_rider/core/contracts/ride_status.dart';

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

  /// Parses a P1 snake_case wire name. Unknown values return null so the
  /// caller decides how to surface a contract mismatch.
  static TripStatus? parse(Object? raw) {
    if (raw is! String) return null;
    final name = raw.trim();
    for (final status in TripStatus.values) {
      if (status.wireName == name) return status;
    }
    return null;
  }
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
        RideStatus.approachingDropoff => TripStatus.approachingDropoff,
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
        RideStatus.paymentFailed => TripStatus.completed,
        RideStatus.bookingExpired => TripStatus.expired,
      };
}

/// The one inbound adapter from the wire to the Rider UI enum (ARCH-10).
///
/// A status field may carry a P1 [TripStatus] wire name (`driver_to_pickup`)
/// or, from older Rider-shaped payloads, a [RideStatus] name
/// (`driverArriving`). Payment and rating are separate machines, so a
/// `completed` trip surfaces as [RideStatus.tripCompleted].
extension RideStatusWire on RideStatus {
  static RideStatus fromTrip(TripStatus trip) => switch (trip) {
        TripStatus.draft => RideStatus.idle,
        TripStatus.quoted => RideStatus.rideOptionsReady,
        TripStatus.requested => RideStatus.bookingRequested,
        // An offer sent to one driver is still a search for the rider.
        TripStatus.searching || TripStatus.offered => RideStatus.findingDriver,
        TripStatus.accepted => RideStatus.driverAssigned,
        TripStatus.driverToPickup => RideStatus.driverArriving,
        TripStatus.arrived => RideStatus.driverWaiting,
        TripStatus.riderOnboard => RideStatus.tripStarted,
        TripStatus.inTrip => RideStatus.tripInProgress,
        TripStatus.approachingDropoff => RideStatus.approachingDropoff,
        TripStatus.completed => RideStatus.tripCompleted,
        TripStatus.cancelledByRider => RideStatus.cancelledByRider,
        TripStatus.cancelledByDriver => RideStatus.cancelledByDriver,
        // A no-show or a failed trip is not a driver cancel: it must not
        // start the "search again for the same ride" path.
        TripStatus.cancelledByAdmin ||
        TripStatus.noShow ||
        TripStatus.failed =>
          RideStatus.cancelledBySystem,
        TripStatus.expired => RideStatus.noDriverFound,
      };

  /// Parses a status field: P1 wire name first, then a legacy [RideStatus]
  /// name. Returns null for anything else.
  static RideStatus? parse(Object? raw) {
    if (raw is! String) return null;
    final trip = TripStatusWire.parse(raw);
    if (trip != null) return fromTrip(trip);
    final name = raw.trim();
    for (final status in RideStatus.values) {
      if (status.name == name) return status;
    }
    return null;
  }
}
