import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class BookingCoordinator {
  Future<String> requestBooking({
    required String rideType,
    required String paymentMethod,
    String? scheduledAt,
  }) async {
    final id = newIdempotencyKey('booking');
    final json = await AppScope.instance.api.post(
      '/api/v1/rides',
      body: {
        'rideType': rideType,
        'paymentMethod': paymentMethod,
        'scheduledAt': scheduledAt,
      },
      idempotencyKey: id,
    );
    final rideId = (json['ride'] is Map ? json['ride']['id'] : id).toString();
    AppScope.instance.ride.restoreFromBackend(
      RideStatus.bookingRequested,
      id: rideId,
    );
    Analytics.bookingSubmitted(rideId: rideId);
    if (scheduledAt == null) {
      AppScope.instance.ride.restoreFromBackend(
        RideStatus.findingDriver,
        id: rideId,
      );
    }
    return rideId;
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
    final key = newIdempotencyKey('booking');
    final json = await AppScope.instance.api.post(
      '/api/v1/rides',
      body: {
        'pickupAddress': pickupAddress,
        'destinationAddress': destinationAddress,
        'pickupLat': pickupLat,
        'pickupLng': pickupLng,
        'destinationLat': destinationLat,
        'destinationLng': destinationLng,
        'rideType': rideType,
        'price': price,
        'paymentMethod': paymentMethod,
      },
      idempotencyKey: key,
    );
    final id = (json['ride'] is Map ? json['ride']['id'] : key).toString();
    Analytics.bookingSubmitted(rideId: id);
    AppScope.instance.ride.restoreFromBackend(RideStatus.findingDriver, id: id);
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

  Future<void> cancel({required String rideId, required String key}) {
    return AppScope.instance.api.post(
      '/api/v1/rides/$rideId/cancel',
      idempotencyKey: key,
    );
  }
}
