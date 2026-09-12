enum RealtimeState { disconnected, connecting, connected, reconnecting, failed }

class RealtimeConnection {
  RealtimeState state = RealtimeState.disconnected;
  int _attempts = 0;

  Duration nextBackoff() {
    _attempts += 1;
    final seconds = (1 << (_attempts.clamp(1, 5) - 1));
    return Duration(seconds: seconds);
  }

  void markConnected() {
    state = RealtimeState.connected;
    _attempts = 0;
  }

  void markDisconnected() => state = RealtimeState.disconnected;
}
