/// Throttles map padding while a sheet drags. Never rebuilds the map widget.
class MapCoordinator {
  MapCoordinator();

  static final instance = MapCoordinator();

  double padding = 0;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  bool shouldPublishPadding(double next) {
    if ((next - padding).abs() < 2) return false;
    final now = DateTime.now();
    if (now.difference(_last).inMilliseconds < 48) return false;
    _last = now;
    padding = next;
    return true;
  }
}
