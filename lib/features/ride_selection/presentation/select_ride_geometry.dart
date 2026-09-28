import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:movera_rider/core/maps/geo_point.dart';

/// D-009: the expanded ride sheet used to reach 72 px below the status bar,
/// hiding almost the whole map — including the destination pin — until
/// Finding. Keep a real slice of map visible above it (large text still gets
/// the full height it needs).
double selectRideMaxSheetHeight(MediaQueryData media) {
  final minH = (348 + media.padding.bottom).clamp(300.0, media.size.height * 0.48);
  final largeText = media.textScaler.scale(1) >= 1.6;
  final topClearance = largeText
      ? 0.0
      : math.max(72.0, media.size.height * 0.34 - media.padding.top);
  final maxH = media.size.height - media.padding.top - topClearance;
  return maxH < minH + 64 ? minH + 64 : maxH;
}

/// D-009: bounds that frame [pickup] and [destination] inside a map of
/// [mapHeight] whose bottom [bottomObstruction] pixels are covered by the
/// sheet. google_maps_flutter only takes one uniform padding, so the covered
/// band is reserved by stretching the bounds southwards.
({GeoPoint southwest, GeoPoint northeast, double padding}) selectRideCameraFit({
  required GeoPoint pickup,
  required GeoPoint destination,
  required double mapHeight,
  required double bottomObstruction,
  double edgePadding = 56,
}) {
  final south = math.min(pickup.latitude, destination.latitude);
  final north = math.max(pickup.latitude, destination.latitude);
  final west = math.min(pickup.longitude, destination.longitude);
  final east = math.max(pickup.longitude, destination.longitude);
  final full = math.max(mapHeight - 2 * edgePadding, 1.0);
  final usable = math.max(
    mapHeight - math.max(bottomObstruction, 0.0) - 2 * edgePadding,
    full * 0.2,
  );
  final stretchedSouth = north - (north - south) * (full / usable);
  return (
    southwest: GeoPoint(math.max(stretchedSouth, -85.0), west),
    northeast: GeoPoint(north, east),
    padding: edgePadding,
  );
}
