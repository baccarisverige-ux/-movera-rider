
enum SafetyKind { shareTrip, sos, maskedCall, ridePin, incident }

class SafetyEvent {
  const SafetyEvent({required this.kind, required this.at, this.rideId});
  final SafetyKind kind;
  final DateTime at;
  final String? rideId;
}
