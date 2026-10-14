import 'package:movera_rider/core/contracts/ride_status.dart';
import 'package:movera_rider/core/contracts/trip_status.dart';

/// Local reservation lifecycle. Backend can later own the same names.
enum ReservationStatus {
  scheduled,
  driverAssignmentPending,
  driverAssigned,
  driverEnRoute,
  driverArrived,
  inProgress,
  completed,
  cancelled;

  bool get isUpcoming =>
      this == scheduled ||
      this == driverAssignmentPending ||
      this == driverAssigned ||
      this == driverEnRoute ||
      this == driverArrived ||
      this == inProgress;

  bool get isCancelled => this == cancelled;

  bool get isCompleted => this == completed;

  bool get hasDriver =>
      this == driverAssigned ||
      this == driverEnRoute ||
      this == driverArrived ||
      this == inProgress ||
      this == completed;

  bool get canEdit => isUpcoming && this != inProgress;

  bool get canCancel => isUpcoming;

  bool get isSearchingDriver => this == driverAssignmentPending;

  bool get isDriverOnTheWay =>
      this == driverEnRoute || this == driverArrived || this == inProgress;

  static ReservationStatus? tryParse(String? name) {
    for (final value in ReservationStatus.values) {
      if (value.name == name) return value;
    }
    return null;
  }

  static ReservationStatus parse(String? name) =>
      tryParse(name) ?? ReservationStatus.scheduled;
}

/// Lives with the reservation domain so core/contracts stays feature-agnostic
/// (ARCH-17). The one reservation -> trip / ride map (ARCH-10).
/// R3: ReservationStatus.driverEnRoute is RideStatus.driverArriving.
extension ReservationStatusAsTripStatus on ReservationStatus {
  TripStatus get tripStatus => switch (this) {
    ReservationStatus.scheduled => TripStatus.requested,
    ReservationStatus.driverAssignmentPending => TripStatus.searching,
    ReservationStatus.driverAssigned => TripStatus.accepted,
    ReservationStatus.driverEnRoute => TripStatus.driverToPickup,
    ReservationStatus.driverArrived => TripStatus.arrived,
    ReservationStatus.inProgress => TripStatus.inTrip,
    ReservationStatus.completed => TripStatus.completed,
    ReservationStatus.cancelled => TripStatus.cancelledByRider,
  };

  RideStatus get asRideStatus => switch (this) {
    ReservationStatus.scheduled => RideStatus.bookingRequested,
    ReservationStatus.driverAssignmentPending => RideStatus.findingDriver,
    ReservationStatus.driverAssigned => RideStatus.driverAssigned,
    ReservationStatus.driverEnRoute => RideStatus.driverArriving,
    ReservationStatus.driverArrived => RideStatus.driverWaiting,
    ReservationStatus.inProgress => RideStatus.tripInProgress,
    ReservationStatus.completed => RideStatus.tripCompleted,
    ReservationStatus.cancelled => RideStatus.cancelledByRider,
  };
}
