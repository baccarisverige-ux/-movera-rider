import 'package:movera_rider/features/booking/data/booking_repository.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';

class BookingController {
  BookingController({BookingRepository? store})
      : _store = store ?? BookingRepository();
  final BookingRepository _store;

  Future<String> submitFinding({
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    required String rideType,
    required double price,
    required String paymentMethod,
    required String quoteId,
    required String quoteSignedPayload,
    required DateTime quoteExpiresAt,
    required int quoteTotalMinor,
    String? rideTypeLabel,
    String? paymentMethodLabel,
    RideNotes notes = RideNotes.empty,
  }) {
    return _store.submitFinding(
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      rideType: rideType,
      price: price,
      paymentMethod: paymentMethod,
      quoteId: quoteId,
      quoteSignedPayload: quoteSignedPayload,
      quoteExpiresAt: quoteExpiresAt,
      quoteTotalMinor: quoteTotalMinor,
      rideTypeLabel: rideTypeLabel,
      paymentMethodLabel: paymentMethodLabel,
      notes: notes,
    );
  }
}
