import 'package:movera_rider/core/utils/request_id.dart';
import 'package:movera_rider/features/safety/data/safety_store.dart';
import 'package:movera_rider/features/safety/domain/ride_check.dart';

class RideCheckService {
  RideCheckService({SafetyStore? store}) : _store = store ?? SafetyStore.shared;

  final SafetyStore _store;

  RideCheckPolicy policy() => _store.rideCheck;

  List<RideCheckEvent> events() => _store.rideCheckEvents;

  Future<RideCheckPolicy> setEnabled(bool enabled) =>
      _store.patchRideCheck(enabled);

  Future<RideCheckEvent> simulate({
    required RideCheckEventType type,
    String rideId = 'ride_qa',
    String? eventId,
    DateTime? at,
  }) {
    return _store.postEvent(
      RideCheckEvent(
        eventId: eventId ?? 'ev_${newRequestId()}',
        rideId: rideId,
        type: type,
        at: at ?? DateTime.now().toUtc(),
      ),
    );
  }

  Future<RideCheckEvent> unexpectedStop({String rideId = 'ride_qa'}) =>
      simulate(type: RideCheckEventType.unexpectedStop, rideId: rideId);

  Future<RideCheckEvent> routeDeviation({String rideId = 'ride_qa'}) =>
      simulate(type: RideCheckEventType.routeDeviation, rideId: rideId);

  Future<RideCheckEvent> sos({required String rideId}) {
    return _store.postEvent(
      RideCheckEvent(
        eventId: 'ev_${newRequestId()}',
        rideId: rideId,
        type: RideCheckEventType.manualSafetyCheck,
        at: DateTime.now().toUtc(),
        payload: const {
          'kind': 'sos',
          'action': 'call_112',
        },
      ),
    );
  }

  Future<RideCheckEvent> resolve(RideCheckEvent event) {
    return _store.respondEvent(
      rideId: event.rideId,
      eventId: event.eventId,
      action: 'resolved',
    );
  }
}
