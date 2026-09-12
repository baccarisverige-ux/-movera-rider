import 'package:movera_rider/features/messages/domain/messages.dart';

class MessagesController {
  final List<ChatMessage> messages = [];

  bool send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return false;
    messages.add(
      ChatMessage(text: text, fromRider: messages.length.isEven),
    );
    return true;
  }
}
