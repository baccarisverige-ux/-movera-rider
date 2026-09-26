/// Push transport contract.
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

class PushUnavailableException implements Exception {
  const PushUnavailableException(this.message);
  final String message;

  @override
  String toString() => 'PushUnavailableException($message)';
}

/// Explicit fail-closed fallback. Release composition rejects this placeholder
/// now that Phase 78 provides the Firebase push transport.
class UnavailablePushService implements PushService {
  const UnavailablePushService();

  Never _unavailable() {
    throw const PushUnavailableException(
      'Push notifications are not connected in this build.',
    );
  }

  @override
  Future<void> register() async => _unavailable();

  @override
  Future<void> unregister() async => _unavailable();
}
