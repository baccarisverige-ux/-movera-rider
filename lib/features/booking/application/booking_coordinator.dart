import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/core/utils/request_id.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class BookingCoordinator {
  Future<String> requestBooking({
    required String rideType,
    required String paymentMethod,
  }) async {
    final id = newIdempotencyKey('booking');
    AppScope.instance.ride.restoreFromBackend(
      RideStatus.bookingRequested,
      id: id,
    );
    Analytics.bookingSubmitted(rideId: id);
    AppScope.instance.ride.restoreFromBackend(RideStatus.findingDriver, id: id);
    return id;
  }

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
  }) async {
    final id = newRequestId();
    Analytics.bookingSubmitted(rideId: id);
    AppScope.instance.ride.restoreFromBackend(
      RideStatus.findingDriver,
      id: id,
    );
    await RideSnapshotStore.save(
      RideSnapshot(
        status: RideStatus.findingDriver,
        savedAt: DateTime.now(),
        pickupAddress: pickupAddress,
        destinationAddress: destinationAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        rideType: rideType,
        price: price,
        paymentMethod: paymentMethod,
        rideId: id,
      ),
    );
    return id;
  }
}
