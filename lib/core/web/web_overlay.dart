import 'package:movera_rider/core/web/web_overlay_io.dart'
    if (dart.library.js_interop) 'package:movera_rider/core/web/web_overlay_web.dart';

void setWebOverlayOpen(bool open) => webSetOverlayOpen(open);

void setWebHomeLock(bool lock) => webSetHomeLock(lock);
