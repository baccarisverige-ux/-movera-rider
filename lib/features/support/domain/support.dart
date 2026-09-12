class SupportRide {
  const SupportRide({
    required this.title,
    required this.when,
    required this.price,
    required this.image,
    this.cancelled = false,
    this.failed = false,
    this.extra,
  });

  final String title;
  final DateTime when;
  final double price;
  final String image;
  final bool cancelled;
  final bool failed;
  final String? extra;

  String get whenLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = when.hour % 12 == 0 ? 12 : when.hour % 12;
    final minute = when.minute.toString().padLeft(2, '0');
    final ampm = when.hour >= 12 ? 'PM' : 'AM';
    return '${months[when.month - 1]} ${when.day} · $hour:$minute $ampm';
  }

  String get longWhen {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final hour = when.hour.toString().padLeft(2, '0');
    final minute = when.minute.toString().padLeft(2, '0');
    return '${when.day} ${months[when.month - 1]} · $hour:$minute · $priceLabel';
  }

  String get monthTitle {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[when.month - 1]} ${when.year}';
  }

  String get priceLabel {
    if (cancelled) {
      return extra == null ? 'kr 0 · Cancelled' : 'kr 0 · Cancelled · $extra';
    }
    if (failed) return 'Failed';
    return 'kr ${price.toStringAsFixed(0)}';
  }
}
