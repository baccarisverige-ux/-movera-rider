abstract class NotificationsRepository {
  Future<void> refresh();
}

class LocalNotificationsRepository implements NotificationsRepository {
  @override
  Future<void> refresh() async {}
}
