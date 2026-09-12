import 'package:movera_rider/features/safety/domain/safety_event.dart';

class SafetyController {
  final events = <SafetyEvent>[];

  void record(SafetyKind kind, {String? rideId}) {
    events.add(SafetyEvent(kind: kind, at: DateTime.now(), rideId: rideId));
  }

  void shareTrip({String? rideId}) =>
      record(SafetyKind.shareTrip, rideId: rideId);

  void sos({String? rideId}) => record(SafetyKind.sos, rideId: rideId);
}
