class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.fromRider,
    this.sentAt,
  });

  final String text;
  final bool fromRider;

  /// Time authored by the message source.
  ///
  /// Local Rider sends always set this. Backend-delivered messages will supply
  /// their server timestamp later. A missing timestamp is rendered honestly
  /// rather than replaced with a fabricated clock value.
  final DateTime? sentAt;
}
