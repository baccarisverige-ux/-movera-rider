/// Why the app cannot read the rider's location.
enum LocationAccessIssue {
  /// Permission was refused, but the system prompt can still be shown again.
  denied,

  /// Permission is blocked (Android "Don't ask again", any iOS refusal):
  /// only the system Settings can change it.
  deniedForever,

  /// Location Services are switched off for the whole device.
  servicesOff,
}
