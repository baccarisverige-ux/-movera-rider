enum MapLifecycle { idle, created, parked, disposed }

class MapLifecycleController {
  MapLifecycle state = MapLifecycle.idle;

  void created() => state = MapLifecycle.created;

  void park() => state = MapLifecycle.parked;

  void resume() {
    if (state == MapLifecycle.parked) state = MapLifecycle.created;
  }

  void dispose() => state = MapLifecycle.disposed;

  bool get isLive => state == MapLifecycle.created;
}
