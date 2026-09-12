enum ConnectivityKind {
  online,
  internetUnavailable,
  backendUnavailable,
  realtimeUnavailable,
  gpsUnavailable,
}

class ConnectivityStatus {
  const ConnectivityStatus({
    this.internet = true,
    this.backend = true,
    this.realtime = true,
    this.gps = true,
  });

  final bool internet;
  final bool backend;
  final bool realtime;
  final bool gps;

  ConnectivityKind get worst {
    if (!internet) return ConnectivityKind.internetUnavailable;
    if (!backend) return ConnectivityKind.backendUnavailable;
    if (!realtime) return ConnectivityKind.realtimeUnavailable;
    if (!gps) return ConnectivityKind.gpsUnavailable;
    return ConnectivityKind.online;
  }
}
