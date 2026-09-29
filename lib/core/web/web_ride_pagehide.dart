import 'package:movera_rider/core/web/web_ride_pagehide_io.dart'
    if (dart.library.js_interop) 'package:movera_rider/core/web/web_ride_pagehide_web.dart';

/// Public-web only: refresh ownership of the current live snapshot on pagehide
/// (Refresh / bfcache leave). It never clears or recreates ride state.
/// Tab switches use visibilitychange — do not wire that here.
void installWebRidePagehide(void Function() onPageHide) =>
    webInstallRidePagehide(onPageHide);
