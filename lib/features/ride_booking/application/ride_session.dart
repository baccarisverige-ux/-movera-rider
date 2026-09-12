import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/utils/stale_guard.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_transition.dart';

class RideSession {
  RideSession({this.rideId});

  String? rideId;
  RideStatus status = RideStatus.idle;
  RideQuote? quote;
  final stale = StaleGuard();

  RideStatus apply(RideStatus next) {
    status = transitionRide(status, next);
    AppLog.info('ride.transition', extra: {'to': status.name, 'rideId': rideId});
    return status;
  }

  void restoreFromBackend(RideStatus backendStatus, {String? id}) {
    rideId = id ?? rideId;
    status = backendStatus;
  }

  void dispose() => stale.dispose();
}
