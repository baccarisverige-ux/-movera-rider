class RideHistoryItem {
  const RideHistoryItem({
    required this.title,
    required this.when,
    required this.price,
    required this.image,
    this.cancelled = false,
    this.featured = false,
  });

  final String title;
  final DateTime when;
  final double price;
  final String image;
  final bool cancelled;
  final bool featured;
}
