enum ChatMessageSender { rider, driver, system }

enum ChatMessageKind { text, systemEvent, quickReply, location }

class ChatMessage {
  const ChatMessage({
    required this.text,
    bool? fromRider,
    ChatMessageSender? sender,
    this.kind = ChatMessageKind.text,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
  }) : assert(
         sender != null || fromRider != null,
         'A chat message needs an explicit sender.',
       ),
       sender = sender ??
           (fromRider == true
               ? ChatMessageSender.rider
               : ChatMessageSender.driver);

  final String text;
  final ChatMessageSender sender;
  final ChatMessageKind kind;

  /// Time authored by the message source.
  ///
  /// Local Rider sends always set this. Backend-delivered messages will supply
  /// their server timestamp later. A missing timestamp is rendered honestly
  /// rather than replaced with a fabricated clock value.
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;

  bool get fromRider => sender == ChatMessageSender.rider;
  bool get isSystem => sender == ChatMessageSender.system;
  bool get isUnreadForRider =>
      sender != ChatMessageSender.rider && readAt == null;

  ChatMessage copyWith({
    String? text,
    ChatMessageSender? sender,
    ChatMessageKind? kind,
    DateTime? sentAt,
    DateTime? deliveredAt,
    DateTime? readAt,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      sender: sender ?? this.sender,
      kind: kind ?? this.kind,
      sentAt: sentAt ?? this.sentAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
    );
  }
}
