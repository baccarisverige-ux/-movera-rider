import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/features/active_ride/data/active_ride_repository.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class ActiveRideController {
  ActiveRideController({ActiveRideRepository? store})
      : _store = store ?? ActiveRideRepository();
  final ActiveRideRepository _store;

  void markArriving() {
    AppScope.instance.ride.restoreFromBackend(RideStatus.driverArriving);
  }

  void markCancelled({String? reasonId}) {
    final id = AppScope.instance.ride.rideId;
    AppScope.instance.ride.restoreFromBackend(RideStatus.cancelledByRider);
    if (id != null) {
      try {
        AppScope.instance.api.post(
          '/api/v1/rides/$id/cancel',
          body: {if (reasonId != null) 'reason': reasonId},
          idempotencyKey: newIdempotencyKey('ride-cancel'),
        );
      } catch (_) {}
    }
    _store.clear();
  }

  void markClosed() {
    AppScope.instance.ride.restoreFromBackend(RideStatus.closed);
    _store.clear();
  }
}
