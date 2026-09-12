import 'package:movera_rider/features/notifications/domain/notifications.dart';

class NotificationsRepository {
  List<AppNotification> all() => const [
        AppNotification(
          kind: 'car',
          title: 'Driver assigned',
          subtitle: 'mac is on the way',
          time: '2min ago',
          read: false,
        ),
        AppNotification(
          kind: 'car',
          title: 'Your Ride has started',
          subtitle: 'Have a safe trip',
          time: '2min ago',
          read: false,
        ),
        AppNotification(
          kind: 'check',
          title: 'Trip Completed',
          subtitle: '\$10.00 Paid',
          time: '2min ago',
          read: false,
        ),
        AppNotification(
          kind: 'car',
          title: 'Driver assigned',
          subtitle: 'mac is on the way',
          time: '2min ago',
          read: true,
        ),
        AppNotification(
          kind: 'car',
          title: 'Driver assigned',
          subtitle: 'mac is on the way',
          time: '2min ago',
          read: true,
        ),
        AppNotification(
          kind: 'car',
          title: 'Driver assigned',
          subtitle: 'mac is on the way',
          time: '2min ago',
          read: true,
        ),
        AppNotification(
          kind: 'car',
          title: 'Driver assigned',
          subtitle: 'mac is on the way',
          time: '2min ago',
          read: true,
        ),
        AppNotification(
          kind: 'car',
          title: 'Driver assigned',
          subtitle: 'mac is on the way',
          time: '2min ago',
          read: true,
        ),
        AppNotification(
          kind: 'car',
          title: 'Driver assigned',
          subtitle: 'mac is on the way',
          time: '2min ago',
          read: true,
        ),
      ];
}
