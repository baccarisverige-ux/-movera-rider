import 'package:movera_rider/features/safety/data/safety_repository.dart';
import 'package:movera_rider/features/safety/domain/safety_event.dart';

class SafetyController {
  SafetyController({SafetyRepository? store})
      : _store = store ?? SafetyRepository();
  final SafetyRepository _store;

  List<SafetyEvent> get events => _store.events;

  void record(SafetyKind kind, {String? rideId}) {
    _store.add(SafetyEvent(kind: kind, at: DateTime.now(), rideId: rideId));
  }

  void shareTrip({String? rideId}) =>
      record(SafetyKind.shareTrip, rideId: rideId);

  void sos({String? rideId}) => record(SafetyKind.sos, rideId: rideId);
}
