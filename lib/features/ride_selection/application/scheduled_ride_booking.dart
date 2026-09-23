import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/features/ride_selection/domain/booking_mode.dart';

/// Shared Book-later confirm path. SelectRide and tests use this so
/// scheduled mode never starts a live Finding Driver search.
class ScheduledRideBooking {
  static String ctaLabel(BookingMode mode, String categoryName) =>
      '${mode.ctaVerb} $categoryName';

  static Future<Reservation> confirm({
    required ReservationController reservations,
    required RideSelectionController selection,
    required ReservationPlace pickup,
    required ReservationPlace destination,
    String? note,
    String? parentReservationId,
    String? editingReservationId,
    double? price,
  }) {
    if (selection.entersFindingDriver || !selection.createsReservation) {
      throw StateError('scheduled booking cannot enter Finding Driver');
    }
    final when = selection.scheduledFor;
    if (when == null) {
      throw StateError('scheduled booking needs a pickup time');
    }
    final ride = selection.rideById(selection.selectedRideId);
    final payment = selection.selectedPaymentItem();
    if (payment == null) {
      throw StateError('scheduled booking needs an available payment method');
    }
    final dropoff = when.add(Duration(minutes: ride.etaMin));
    final nextPrice = price ?? selection.priceFor(ride.id, ride.price);
    if (editingReservationId != null) {
      return reservations.update(
        editingReservationId,
        ReservationPatch(
          scheduledPickupAt: when,
          estimatedDropoffAt: dropoff,
          pickup: pickup,
          destination: destination,
          categoryId: ride.id,
          categoryName: ride.name,
          categoryImage: ride.image,
          passengerCount: ride.seats,
          price: nextPrice,
          paymentMethod: payment.name,
          note: note,
        ),
      );
    }
    return reservations.create(
      ReservationDraft(
        scheduledPickupAt: when,
        estimatedDropoffAt: dropoff,
        pickup: pickup,
        destination: destination,
        categoryId: ride.id,
        categoryName: ride.name,
        categoryImage: ride.image,
        passengerCount: ride.seats,
        price: nextPrice,
        paymentMethod: payment.name,
        note: note,
        parentReservationId: parentReservationId,
      ),
    );
  }
}
