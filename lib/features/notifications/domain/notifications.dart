class AppNotification {
  const AppNotification({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.read,
  });

  final String kind;
  final String title;
  final String subtitle;
  final String time;
  final bool read;
}
