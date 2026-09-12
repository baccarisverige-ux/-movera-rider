abstract class ScheduledRidesRepository {
  Future<void> refresh();
}

class LocalScheduledRidesRepository implements ScheduledRidesRepository {
  @override
  Future<void> refresh() async {}
}
