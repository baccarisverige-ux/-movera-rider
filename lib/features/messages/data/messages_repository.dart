import 'package:movera_rider/features/messages/domain/messages.dart';

class MessagesRepository {
  MessagesRepository() : _messages = <ChatMessage>[];

  MessagesRepository._(this._messages);

  static final Map<String, List<ChatMessage>> _rideSessions =
      <String, List<ChatMessage>>{};

  /// Session-scoped conversation for one active ride.
  ///
  /// This intentionally survives closing/reopening the Chat screen in the same
  /// app process, but it is not durable storage and must not be mistaken for a
  /// backend conversation history.
  factory MessagesRepository.forRide(String rideId) {
    final key = rideId.trim();
    if (key.isEmpty) return MessagesRepository();
    return MessagesRepository._(
      _rideSessions.putIfAbsent(key, () => <ChatMessage>[]),
    );
  }

  final List<ChatMessage> _messages;

  List<ChatMessage> get messages => List<ChatMessage>.unmodifiable(_messages);

  void add(ChatMessage message) => _messages.add(message);
}
