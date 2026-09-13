import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/features/pickup/presentation/confirm_pickup_spot.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_format.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_review.dart';
import 'package:movera_rider/features/reservations/presentation/review_changes.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/features/ride_selection/application/scheduled_ride_booking.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

/// Confirm pickup → review → create/update. Never Finding Driver.
class ScheduledRideCheckout {
  static ReservationDraft draftFrom({
    required RideSelectionController selection,
    required ReservationPlace pickup,
    required ReservationPlace destination,
    String? note,
    String? parentReservationId,
    double? price,
  }) {
    final when = selection.scheduledFor;
    if (when == null) {
      throw StateError('scheduled checkout needs a pickup time');
    }
    final ride = selection.rideById(selection.selectedRideId);
    final payments = selection.payments();
    final payment =
        payments[selection.selectedPayment.clamp(0, payments.length - 1)];
    return ReservationDraft(
      scheduledPickupAt: when,
      estimatedDropoffAt: when.add(Duration(minutes: ride.etaMin)),
      pickup: pickup,
      destination: destination,
      categoryId: ride.id,
      categoryName: ride.name,
      categoryImage: ride.image,
      passengerCount: ride.seats,
      price: price ?? selection.priceFor(ride.id, ride.price),
      paymentMethod: payment.name,
      note: note,
      parentReservationId: parentReservationId,
    );
  }

  static Future<Reservation?> run(
    BuildContext context, {
    required ReservationController reservations,
    required RideSelectionController selection,
    required ReservationPlace pickup,
    required ReservationPlace destination,
    required LatLng pickupPosition,
    String? note,
    String? parentReservationId,
    String? editingReservationId,
    Reservation? original,
  }) async {
    if (selection.entersFindingDriver || !selection.createsReservation) {
      throw StateError('scheduled checkout cannot enter Finding Driver');
    }
    final ride = selection.rideById(selection.selectedRideId);
    final when = selection.scheduledFor;
    if (when == null) return null;

    final spot = await Navigator.of(context).push<ConfirmPickupResult>(
      RightToLeftTransition(
        ConfirmPickupSpot(
          initialPosition: pickupPosition,
          initialAddress: pickup.label,
          scheduledSummary:
              '${ReservationFormat.weekdayDate(when)} · ${ReservationFormat.time(when)}',
          categoryName: ride.name,
          confirmLabel: 'Confirm pickup spot',
        ),
      ),
    );
    if (spot == null || !context.mounted) return null;

    final confirmedPickup = ReservationPlace(
      label: spot.address,
      lat: spot.position.latitude,
      lng: spot.position.longitude,
      subtitle: pickup.subtitle,
    );
    final draft = draftFrom(
      selection: selection,
      pickup: confirmedPickup,
      destination: destination,
      note: note,
      parentReservationId: parentReservationId,
    );

    if (editingReservationId != null && original != null) {
      final accepted = await Navigator.of(context).push<bool>(
        BottomToTopTransition(
          ReviewChangesPage(
            original: original,
            draft: draft,
            controller: reservations,
          ),
        ),
      );
      if (accepted != true || !context.mounted) return null;
      return ScheduledRideBooking.confirm(
        reservations: reservations,
        selection: selection,
        pickup: confirmedPickup,
        destination: destination,
        note: note,
        editingReservationId: editingReservationId,
        price: draft.price,
      );
    }

    final accepted = await Navigator.of(context).push<bool>(
      BottomToTopTransition(
        ReservationReviewPage(
          draft: draft,
          ctaLabel: ScheduledRideBooking.ctaLabel(
            selection.bookingMode,
            ride.name,
          ),
        ),
      ),
    );
    if (accepted != true || !context.mounted) return null;
    return ScheduledRideBooking.confirm(
      reservations: reservations,
      selection: selection,
      pickup: confirmedPickup,
      destination: destination,
      note: note,
      parentReservationId: parentReservationId,
      price: draft.price,
    );
  }
}
