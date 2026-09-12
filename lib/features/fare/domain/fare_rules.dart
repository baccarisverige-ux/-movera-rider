class FareRules {
  static double nudge({
    required double current,
    required double catalog,
    required int delta,
  }) {
    final minimum = (catalog * 0.65).roundToDouble();
    final maximum = (catalog * 1.8).roundToDouble();
    return (current + delta).clamp(minimum, maximum).roundToDouble();
  }
}
