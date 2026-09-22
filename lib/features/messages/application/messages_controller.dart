import 'package:movera_rider/features/messages/data/messages_repository.dart';
import 'package:movera_rider/features/messages/domain/messages.dart';

class MessagesController {
  MessagesController({
    MessagesRepository? store,
    DateTime Function()? now,
  }) : _store = store ?? MessagesRepository(),
       _now = now ?? DateTime.now;

  factory MessagesController.forRide(
    String? rideId, {
    DateTime Function()? now,
  }) {
    final id = rideId?.trim() ?? '';
    return MessagesController(
      store: id.isEmpty ? MessagesRepository() : MessagesRepository.forRide(id),
      now: now,
    );
  }

  final MessagesRepository _store;
  final DateTime Function() _now;

  List<ChatMessage> get messages => _store.messages;
  int get unreadCount => _store.unreadCount;

  bool send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return false;

    // A local send is always authored by the Rider. Driver-authored messages
    // must arrive from a real transport later; never manufacture them here.
    _store.add(
      ChatMessage(
        text: text,
        fromRider: true,
        sentAt: _now(),
      ),
    );
    return true;
  }

  /// Adapter seam for a future transport. It never synthesizes Driver/System
  /// messages; callers must provide the authoritative message object.
  void receive(ChatMessage message) => _store.ingest(message);

  void markAllRead() => _store.markAllRead(_now());
}

