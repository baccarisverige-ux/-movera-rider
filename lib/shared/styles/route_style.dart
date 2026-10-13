import 'package:flutter/material.dart';

/// Shared map-route appearance for every Rider map.
///
/// The route runs from the green pickup to the blue destination, the same
/// colours as the pickup and destination icons in "Where to?", with a thin
/// white casing so it reads on any map.
abstract final class RiderRouteStyle {
  static const Color pickup = Color(0xFF079A60);
  static const Color destination = Color(0xFF1769E8);
  static const Color casing = Colors.white;

  /// Kept for callers that need one colour (e.g. a fallback line).
  static const Color color = Color(0xFF0F82A4);

  /// The route colour at [t] (0 = pickup, 1 = destination).
  static Color at(double t) => Color.lerp(pickup, destination, t.clamp(0, 1))!;
}
