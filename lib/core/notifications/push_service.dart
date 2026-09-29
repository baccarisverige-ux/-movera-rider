import 'package:movera_rider/core/notifications/push_payload.dart';

/// Push transport contract.
abstract class PushService {
  Future<void> register();
  Future<void> unregister();

  Stream<PushPayload> get foregroundMessages;
  Stream<PushPayload> get openedMessages;
  Future<PushPayload?> takeInitialMessage();
}

class NoopPushService implements PushService {
  @override
  Future<void> register() async {}

  @override
  Future<void> unregister() async {}

  @override
  Stream<PushPayload> get foregroundMessages => const Stream.empty();

  @override
  Stream<PushPayload> get openedMessages => const Stream.empty();

  @override
  Future<PushPayload?> takeInitialMessage() async => null;
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

  @override
  Stream<PushPayload> get foregroundMessages => const Stream.empty();

  @override
  Stream<PushPayload> get openedMessages => const Stream.empty();

  @override
  Future<PushPayload?> takeInitialMessage() async => null;
}
