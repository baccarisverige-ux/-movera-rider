import 'package:movera_rider/features/messages/data/messages_repository.dart';
import 'package:movera_rider/features/messages/domain/messages.dart';

class MessagesController {
  MessagesController({MessagesRepository? store})
      : _store = store ?? MessagesRepository();
  final MessagesRepository _store;

  List<ChatMessage> get messages => _store.messages;

  bool send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return false;
    _store.add(ChatMessage(text: text, fromRider: messages.length.isEven));
    return true;
  }
}
