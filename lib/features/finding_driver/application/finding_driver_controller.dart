import 'dart:async';

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class FindingDriverController {
  Timer? _tick;
  Timer? _match;

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
      RideSnapshotStore.save(
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
    RideSnapshotStore.clear();
  }

  void dispose() {
    _tick?.cancel();
    _match?.cancel();
  }
}
