import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_for_driver.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

abstract final class ReservationLiveRide {
  static const _fallback = LatLng(59.3293, 18.0686);

  static MatchedDriver driverOf(ReservationDriver driver) {
    final parts = (driver.vehicle ?? '')
        .split(' ')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return MatchedDriver(
      id: 'rsv-driver-${driver.firstName}',
      firstName: driver.firstName,
      rating: driver.rating,
      vehicleMake: parts.isNotEmpty ? parts.first : driver.vehicle,
      vehicleModel: parts.length > 1 ? parts.sublist(1).join(' ') : null,
      plate: driver.plate,
      photoAsset: driver.photoAsset,
    );
  }

  static RideNotes notesOf(Reservation ride) {
    final note = ride.note ?? '';
    return RideNotes(
      bags: note.contains('Bags'),
      pet: note.contains('Pet'),
      baby: note.contains('Baby'),
      child: note.contains('Child'),
    );
  }

  static LatLng _point(ReservationPlace place) {
    if (place.lat != null && place.lng != null) {
      return LatLng(place.lat!, place.lng!);
    }
    return _fallback;
  }

  static WaitingForDriver pageFor(Reservation ride) {
    return WaitingForDriver(
      pickupAddress: ride.pickup.label,
      destinationAddress: ride.destination.label,
      pickupPosition: _point(ride.pickup),
      destinationPosition: _point(ride.destination),
      rideType: ride.categoryName,
      price: ride.price,
      paymentMethod: ride.paymentMethod,
      notes: notesOf(ride),
      driver: ride.driver == null ? null : driverOf(ride.driver!),
    );
  }

  static Future<void> open(
    BuildContext context,
    Reservation ride, {
    bool replace = false,
  }) {
    final route = BottomToTopTransition(pageFor(ride));
    if (replace) {
      return Navigator.of(context).pushReplacement(route);
    }
    return Navigator.of(context).push(route);
  }
}
