import 'package:movera_rider/core/maps/geo_point.dart';

/// The one place a drawn route comes from. Screens must not invent routes.
///
/// Today this returns the direct pickup→destination line, because the app has
/// no Directions provider wired up yet: there is no Maps key on web and no
/// billable Directions call anywhere in the project. That is an honest
/// stand-in, not a road route, and the rider sees a straight line on the map.
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
