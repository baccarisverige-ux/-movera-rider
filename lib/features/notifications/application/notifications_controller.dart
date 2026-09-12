import 'package:movera_rider/features/notifications/data/notifications_repository.dart';
import 'package:movera_rider/features/notifications/domain/notifications.dart';

class NotificationsController {
  NotificationsController({NotificationsRepository? store})
      : _store = store ?? NotificationsRepository();
  final NotificationsRepository _store;

  List<AppNotification> feed() => _store.all();
}
