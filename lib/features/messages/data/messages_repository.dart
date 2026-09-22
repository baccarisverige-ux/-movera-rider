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

  List<ChatMessage> get messages =>
      List<ChatMessage>.unmodifiable(_messages);

  int get unreadCount =>
      _messages.where((message) => message.isUnreadForRider).length;

  void add(ChatMessage message) => _messages.add(message);

  /// Inbound seam only. It stores transport-authored driver/system messages
  /// exactly as supplied; it never invents a counterpart message.
  void ingest(ChatMessage message) {
    if (message.sender == ChatMessageSender.rider) {
      throw ArgumentError.value(
        message.sender,
        'message.sender',
        'Inbound messages must be driver or system authored.',
      );
    }
    _messages.add(message);
  }

  void markAllRead(DateTime at) {
    for (var i = 0; i < _messages.length; i += 1) {
      final message = _messages[i];
      if (!message.isUnreadForRider) continue;
      _messages[i] = message.copyWith(readAt: at);
    }
  }
}
