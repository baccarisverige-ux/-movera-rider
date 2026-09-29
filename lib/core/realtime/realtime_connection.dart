import 'dart:async';

enum RealtimeState { disconnected, connecting, connected, reconnecting, failed }

class RealtimeConnection {
  RealtimeState _state = RealtimeState.disconnected;
  int _attempts = 0;
  final StreamController<RealtimeState> _states =
      StreamController<RealtimeState>.broadcast(sync: true);

  RealtimeState get state => _state;

  /// State changes are observable so Rider surfaces can reflect transport
  /// availability without polling or inventing ride state.
  Stream<RealtimeState> get states => _states.stream;

  /// Keep the setter for existing transport code while making every change
  /// flow through the same observable source of truth.
  set state(RealtimeState value) => _setState(value);

  void _setState(RealtimeState value) {
    if (_state == value) return;
    _state = value;
    if (!_states.isClosed) _states.add(value);
  }

  Duration nextBackoff() {
    _attempts += 1;
    final seconds = (1 << (_attempts.clamp(1, 5) - 1));
    return Duration(seconds: seconds);
  }

  void markConnected() {
    _attempts = 0;
    _setState(RealtimeState.connected);
  }

  void markDisconnected() => _setState(RealtimeState.disconnected);

  void markReconnecting() => _setState(RealtimeState.reconnecting);

  void markFailed() => _setState(RealtimeState.failed);

  void dispose() {
    if (!_states.isClosed) _states.close();
  }
}
