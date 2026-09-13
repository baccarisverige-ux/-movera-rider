import 'package:movera_rider/core/web/web_overlay_io.dart'
    if (dart.library.html) 'package:movera_rider/core/web/web_overlay_web.dart';

void setWebOverlayOpen(bool open) => webSetOverlayOpen(open);
