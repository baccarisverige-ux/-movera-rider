import 'package:flutter/material.dart';

/// Shared map-route appearance for every Rider map.
/// Waze iPhone app route colour (#5235DF, sampled from Waze App Store
/// screenshots), the same value Driver uses (DriverRouteStyle.color).
abstract final class RiderRouteStyle {
  static const Color color = Color(0xFF5235DF);
}
