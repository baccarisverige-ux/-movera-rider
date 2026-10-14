import 'package:movera_rider/features/reservations/domain/reservation.dart';

/// Finished Book now rides for History (ARCH-12, contract C-5).
///
/// PROPOSED, needs agreement with Driver, Admin and backend:
/// `GET /api/v1/rider/trips?cursor=` → `{code, trips: [C-6 projection +
/// endedAt, cancellationReason], nextCursor}`, newest first, including
/// cancelled trips.
abstract interface class RideHistoryRepository {
  /// Newest first.
  Future<List<Reservation>> loadOnDemand();
}
