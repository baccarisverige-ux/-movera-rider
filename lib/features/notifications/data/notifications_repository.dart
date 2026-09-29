import 'dart:async';

import 'package:movera_rider/core/notifications/push_payload.dart';
import 'package:movera_rider/features/notifications/domain/notifications.dart';

class NotificationsRepository {
  NotificationsRepository({DateTime Function()? now})
      : _now = now ?? DateTime.now;

  static final NotificationsRepository shared = NotificationsRepository();

  final DateTime Function() _now;
  final List<AppNotification> _items = <AppNotification>[];
  final StreamController<List<AppNotification>> _changes =
      StreamController<List<AppNotification>>.broadcast();

  List<AppNotification> all() => List<AppNotification>.unmodifiable(_items);

  Stream<List<AppNotification>> watch() => _changes.stream;

  void ingest(PushPayload payload, {required bool read}) {
    final title = payload.title?.trim();
    final body = payload.body?.trim();

    // Data-only ride pushes still drive authoritative ride resync, but they do
    // not fabricate user-facing copy for the Notifications feed.
    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return;
    }

    final messageId = payload.messageId?.trim();
    if (messageId != null && messageId.isNotEmpty) {
      final existing = _items.indexWhere(
        (item) => item.messageId == messageId,
      );
      if (existing >= 0) {
        if (read && !_items[existing].read) {
          _items[existing] = _items[existing].copyWith(read: true);
          _emit();
        }
        return;
      }
    }

    final at = (payload.sentAt ?? _now()).toLocal();
    _items.insert(
      0,
      AppNotification(
        kind: payload.isRideEvent ? 'ride' : 'info',
        title: title?.isNotEmpty == true ? title! : 'Movera',
        subtitle: body?.isNotEmpty == true ? body! : payload.type,
        time: _formatTime(at),
        read: read,
        messageId: messageId,
        rideId: payload.rideId,
        deepLink: payload.deepLink,
      ),
    );
    _emit();
  }

  void markRead(String? messageId) {
    final id = messageId?.trim();
    if (id == null || id.isEmpty) return;
    final index = _items.indexWhere((item) => item.messageId == id);
    if (index < 0 || _items[index].read) return;
    _items[index] = _items[index].copyWith(read: true);
    _emit();
  }

  void clearForTest() {
    _items.clear();
    _emit();
  }

  void _emit() {
    if (_changes.isClosed) return;
    _changes.add(all());
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
