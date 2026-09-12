/// Contract only. Live FCM/APNs is not connected yet.
abstract class PushService {
  Future<void> register();
  Future<void> unregister();
}

class NoopPushService implements PushService {
  @override
  Future<void> register() async {}

  @override
  Future<void> unregister() async {}
}
