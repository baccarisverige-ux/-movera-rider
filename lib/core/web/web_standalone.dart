import 'package:movera_rider/core/web/web_standalone_io.dart'
    if (dart.library.js_interop) 'package:movera_rider/core/web/web_standalone_web.dart';

/// True when the app is running as an installed PWA, not a browser tab.
bool isInstalledWebApp() => webIsInstalledApp();
