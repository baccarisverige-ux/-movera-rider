double normalizeHeading(double degrees) {
  var value = degrees % 360;
  if (value < 0) value += 360;
  return value;
}

/// Shortest signed turn in degrees. 359 → 1 is +2, not -358.
double shortestTurn(double fromDeg, double toDeg) {
  var delta = normalizeHeading(toDeg) - normalizeHeading(fromDeg);
  if (delta > 180) delta -= 360;
  if (delta < -180) delta += 360;
  return delta;
}

double lerpHeading(double fromDeg, double toDeg, double t) {
  final clamped = t.clamp(0.0, 1.0);
  return normalizeHeading(fromDeg + shortestTurn(fromDeg, toDeg) * clamped);
}
