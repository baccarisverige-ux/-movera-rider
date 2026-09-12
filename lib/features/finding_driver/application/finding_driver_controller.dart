import 'dart:async';

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/features/finding_driver/data/finding_driver_repository.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class FindingDriverController {
  FindingDriverController({FindingDriverRepository? store})
      : _store = store ?? FindingDriverRepository();
  final FindingDriverRepository _store;
  Timer? _tick;
  Timer? _match;

  void startFrom({
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    required String rideType,
    required double price,
    required String paymentMethod,
    required void Function(int remaining) onTick,
    required void Function() onMatched,
  }) {
    start(
      seconds: 12,
      snapshot: RideSnapshot(
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
        rideId: AppScope.instance.ride.rideId,
      ),
      onTick: onTick,
      onMatched: onMatched,
    );
  }

  void start({
    required int seconds,
    required RideSnapshot snapshot,
    required void Function(int remaining) onTick,
    required void Function() onMatched,
  }) {
    AppScope.instance.ride.restoreFromBackend(RideStatus.findingDriver);
    var remaining = seconds;
    _tick?.cancel();
    _match?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remaining > 0) {
        remaining -= 1;
        onTick(remaining);
      } else {
        timer.cancel();
      }
    });
    _match = Timer(Duration(seconds: seconds), () {
      AppScope.instance.ride.restoreFromBackend(RideStatus.driverAssigned);
      Analytics.driverFound(rideId: AppScope.instance.ride.rideId);
      _store.save(
        RideSnapshot(
          status: RideStatus.driverAssigned,
          savedAt: DateTime.now(),
          pickupAddress: snapshot.pickupAddress,
          destinationAddress: snapshot.destinationAddress,
          pickupLat: snapshot.pickupLat,
          pickupLng: snapshot.pickupLng,
          destinationLat: snapshot.destinationLat,
          destinationLng: snapshot.destinationLng,
          rideType: snapshot.rideType,
          price: snapshot.price,
          paymentMethod: snapshot.paymentMethod,
          rideId: AppScope.instance.ride.rideId,
        ),
      );
      onMatched();
    });
  }

  void cancelSearch() {
    Analytics.rideCancelled();
    AppScope.instance.ride.restoreFromBackend(RideStatus.cancelledByRider);
    _store.clear();
  }

  void dispose() {
    _tick?.cancel();
    _match?.cancel();
  }
}
