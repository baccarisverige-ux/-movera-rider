import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';

/// Gives [selection] the server quote a real Select Ride screen loads for
/// [rideId] before Book for later (ARCH-16: no scheduled booking without
/// one). The price is the selection's current one unless [kr] is given.
void adoptScheduledQuote(
  RideSelectionController selection,
  String rideId, {
  double? kr,
}) {
  final price =
      kr ?? selection.priceFor(rideId, selection.rideById(rideId).price);
  selection.adoptQuote(
    rideId,
    RideQuote(
      id: 'q_test_$rideId',
      rideType: rideId,
      totalMinor: (price * 100).round(),
      currency: 'SEK',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      signedPayload: 'test-signed',
    ),
  );
}
