import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';

/// "My current ride" as the server knows it (ARCH-12, contract C-5).
///
/// PROPOSED, needs agreement with Driver, Admin and backend:
/// `GET /api/v1/rider/trips/active` → `{code, trip}` with the C-6 ride
/// projection, or `204` / `trip: null` when the rider has no live trip.
/// Restore and notification taps ask it when this device has no snapshot of
/// the ride (the app died before saving it, storage was cleared, or this is
/// a second device).
abstract interface class ActiveTripRepository {
  /// The rider's live trip, or null when there is none.
  Future<RideSnapshot?> fetchActive();
}
