import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';
import 'package:movera_rider/features/trips/domain/trip.dart';
import 'package:movera_rider/features/trips/domain/trip_status.dart';

extension ReservationTripAdapter on Reservation {
  Trip toTripContract() {
    return Trip(
      tripId: reservationId,
      status: _tripStatus(status),
      categoryId: categoryId,
      paymentMethodId: paymentMethod,
      createdAt: createdAt,
      updatedAt: cancelledAt ?? createdAt,
      schedule: TripSchedule(
        scheduledFor: scheduledPickupAt,
        parentTripId: parentReservationId,
      ),
      cancellation: cancellationActor == null || cancelledAt == null
          ? null
          : TripCancellation(
              actor: cancellationActor!,
              reasonId: cancellationReason,
              at: cancelledAt!,
            ),
    );
  }
}

TripStatus _tripStatus(ReservationStatus status) {
  switch (status) {
    case ReservationStatus.scheduled:
      return TripStatus.requested;
    case ReservationStatus.driverAssignmentPending:
      return TripStatus.searching;
    case ReservationStatus.driverAssigned:
      return TripStatus.accepted;
    case ReservationStatus.driverEnRoute:
      return TripStatus.driverToPickup;
    case ReservationStatus.driverArrived:
      return TripStatus.arrived;
    case ReservationStatus.inProgress:
      return TripStatus.inTrip;
    case ReservationStatus.completed:
      return TripStatus.completed;
    case ReservationStatus.cancelled:
      return TripStatus.cancelledByRider;
  }
}
