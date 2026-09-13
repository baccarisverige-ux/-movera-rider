import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/maps/map_owners.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/ride_scheduled.dart';
import 'package:movera_rider/features/ride_selection/presentation/select_ride.dart';
import 'package:movera_rider/features/scheduled_rides/application/scheduled_rides_controller.dart';

/// After Plan your ride + calendar, open the same category cards as Book now
/// with bookingMode = scheduled so the CTA is Schedule [category].
Future<void> openScheduledCategorySelector(
  BuildContext context, {
  required ScheduledRideSession session,
  String? editingReservationId,
  String? initialRideId,
}) async {
  final pickupLabel = session.pickup.trim().isEmpty
      ? 'Current location'
      : session.pickup.trim();
  final destinationLabel = session.dropoff.trim();
  final pickupPosition = await resolveScheduledPoint(pickupLabel);
  final destinationPosition = await resolveScheduledPoint(destinationLabel);
  if (!context.mounted) return;

  AppScope.instance.maps.detach(owner: MapOwners.schedule);

  final created = await Navigator.of(context).push<Reservation>(
    MaterialPageRoute(
      builder: (_) => SelectRide(
        pickupAddress: pickupLabel,
        destinationAddress: destinationLabel,
        pickupPosition: pickupPosition,
        destinationPosition: destinationPosition,
        stops: List<String>.from(session.stops),
        bookingMode: BookingMode.scheduled,
        lockBookingMode: true,
        initialScheduledFor: session.scheduledAt,
        initialRideId: initialRideId ?? session.rideType,
        note: session.note.trim().isEmpty ? null : session.note.trim(),
        editingReservationId: editingReservationId,
        onScheduled: editingReservationId == null
            ? (context, id) => RideScheduledPage.open(
                context,
                reservationId: id,
                untilHome: true,
              )
            : null,
      ),
    ),
  );
  if (editingReservationId != null && created != null && context.mounted) {
    Navigator.pop(context);
  }
}

const LatLng kScheduledFallbackPoint = LatLng(59.3293, 18.0686);

Future<LatLng> resolveScheduledPoint(String label) async {
  final clean = label.trim();
  if (clean.isEmpty || clean.toLowerCase() == 'current location') {
    try {
      final pos = await AppScope.instance.location.getCurrentPosition().timeout(
        const Duration(milliseconds: 600),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return kScheduledFallbackPoint;
    }
  }
  try {
    final result = await AppScope.instance.geocoding
        .geocodeAddress(clean)
        .timeout(const Duration(milliseconds: 900));
    if (result != null) {
      return LatLng(result.latitude, result.longitude);
    }
  } catch (_) {}
  return kScheduledFallbackPoint;
}
