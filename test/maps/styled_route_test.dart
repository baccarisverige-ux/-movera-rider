import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/maps/route_polyline.dart';
import 'package:movera_rider/shared/styles/route_style.dart';

void main() {
  const route = Polyline(
    polylineId: PolylineId('route'),
    points: [LatLng(59.19, 17.62), LatLng(59.22, 17.70), LatLng(59.25, 17.80)],
    width: 4,
  );

  test('route is a white casing under a green-to-blue line', () {
    final pieces = styledRoute(route).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final casing = pieces.first;
    expect(casing.color, RiderRouteStyle.casing);
    expect(casing.width, 8);
    final line = pieces.skip(1).toList();
    expect(line.length, 12);
    expect(line.first.points.first, route.points.first);
    expect(line.last.points.last, route.points.last);
    // Starts green, ends blue.
    expect(
      (line.first.color.g - RiderRouteStyle.pickup.g).abs(),
      lessThan(0.1),
    );
    expect(
      (line.last.color.b - RiderRouteStyle.destination.b).abs(),
      lessThan(0.1),
    );
    // Pieces join up with no gaps.
    for (var i = 1; i < line.length; i++) {
      expect(line[i].points.first, line[i - 1].points.last);
    }
  });

  test('a single point route is left as it is', () {
    const dot = Polyline(
      polylineId: PolylineId('dot'),
      points: [LatLng(59.19, 17.62)],
    );
    expect(styledRoute(dot), {dot});
  });
}
