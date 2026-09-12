abstract class MessagesRepository {
  Future<void> refresh();
}

class LocalMessagesRepository implements MessagesRepository {
  @override
  Future<void> refresh() async {}
}
