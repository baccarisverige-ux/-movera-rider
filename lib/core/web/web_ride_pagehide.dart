import 'package:movera_rider/core/web/web_ride_pagehide_io.dart'
    if (dart.library.html) 'package:movera_rider/core/web/web_ride_pagehide_web.dart';

/// Public-web only: clear ride snapshot on pagehide (Refresh / bfcache leave).
/// Tab switches use visibilitychange — do not wire that here.
void installWebRidePagehide(void Function() onPageHide) =>
    webInstallRidePagehide(onPageHide);
