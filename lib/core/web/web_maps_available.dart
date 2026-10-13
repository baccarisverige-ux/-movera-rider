import 'package:movera_rider/core/web/web_maps_available_io.dart'
    if (dart.library.js_interop) 'package:movera_rider/core/web/web_maps_available_web.dart';

/// Whether the Google Maps engine can draw a map here. Always true on
/// phones; on the web only once the Maps JavaScript API has loaded — building
/// a map without it throws inside the maps plugin.
bool googleMapsAvailable() => webGoogleMapsAvailable();
