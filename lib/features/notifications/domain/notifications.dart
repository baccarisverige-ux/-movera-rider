class AppNotification {
  const AppNotification({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.read,
    this.messageId,
    this.rideId,
    this.deepLink,
  });

  final String kind;
  final String title;
  final String subtitle;
  final String time;
  final bool read;
  final String? messageId;
  final String? rideId;
  final String? deepLink;

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      kind: kind,
      title: title,
      subtitle: subtitle,
      time: time,
      read: read ?? this.read,
      messageId: messageId,
      rideId: rideId,
      deepLink: deepLink,
    );
  }
}
