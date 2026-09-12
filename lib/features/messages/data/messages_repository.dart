import 'package:movera_rider/features/messages/domain/messages.dart';

class MessagesRepository {
  final messages = <ChatMessage>[];

  void add(ChatMessage message) => messages.add(message);
}
