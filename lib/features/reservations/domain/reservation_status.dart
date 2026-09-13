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

  static ReservationStatus parse(String? name) {
    for (final value in ReservationStatus.values) {
      if (value.name == name) return value;
    }
    return ReservationStatus.scheduled;
  }
}
