class DirectionConeState {
  const DirectionConeState({
    required this.heading,
    this.width = 48,
    this.radius = 42,
    this.opacity = 0.28,
    this.accuracy,
  });

  final double heading;
  final double width;
  final double radius;
  final double opacity;
  final double? accuracy;
}
