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

extension TripStatusX on TripStatus {
  bool get isTerminal =>
      this == TripStatus.completed ||
      this == TripStatus.cancelledByRider ||
      this == TripStatus.cancelledByDriver ||
      this == TripStatus.cancelledByAdmin ||
      this == TripStatus.noShow ||
      this == TripStatus.expired ||
      this == TripStatus.failed;

  bool get isActive =>
      this == TripStatus.requested ||
      this == TripStatus.searching ||
      this == TripStatus.offered ||
      this == TripStatus.accepted ||
      this == TripStatus.driverToPickup ||
      this == TripStatus.arrived ||
      this == TripStatus.riderOnboard ||
      this == TripStatus.inTrip ||
      this == TripStatus.approachingDropoff;
}
