import 'package:flutter/foundation.dart';
import 'package:movera_rider/core/web/map_touch_io.dart'
    if (dart.library.js_interop) 'package:movera_rider/core/web/map_touch_web.dart';

/// A running watch on fingers touching a Google map on the web page.
abstract class MapTouchSubscription {
  void cancel();
}

/// Tells [onDown] when a finger (or mouse button) goes down on a Google map
/// element and [onUp] when it lifts again, anywhere on the page.
///
/// On the web the map is a browser element, so Flutter's own pointer events
/// do not reach the widgets behind it; this listens on the document instead.
/// Phones get their touches through the map plugin and this returns null.
MapTouchSubscription? watchMapTouch({
  required VoidCallback onDown,
  required VoidCallback onUp,
}) => watchWebMapTouch(onDown: onDown, onUp: onUp);
