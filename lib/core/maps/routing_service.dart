import 'package:movera_rider/core/maps/geo_point.dart';

/// The one place a drawn route comes from. Screens must not invent routes.
///
/// Today this returns the direct pickup→destination line, because no
/// Directions provider is wired up: nothing in the project calls the
/// Directions API. That is an honest stand-in, not a road route, and the rider
/// sees a straight line on the map.
///
/// A Maps key does exist — `MAPS_WEB_API_KEY` is injected into index.html by
/// publish-web-live.yml at deploy time, and the native builds read
/// `MAPS_API_KEY` — so wiring a real provider is a question of enabling
/// Directions on that key, not of obtaining one.
///
/// It stays a seam on purpose. When a real provider arrives, [line] is the
/// only method that changes and every map in the app picks up road geometry at
/// once — which is why [MapFacade.drawRoute] and the booking screens all go
/// through here instead of building their own two-point polyline.
class RoutingService {
  List<GeoPoint> line({required GeoPoint from, required GeoPoint to}) => [
    from,
    to,
  ];
}
