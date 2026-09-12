class PushPayload {
  const PushPayload({
    required this.type,
    this.rideId,
    this.deepLink,
  });

  final String type;
  final String? rideId;
  final String? deepLink;
}
