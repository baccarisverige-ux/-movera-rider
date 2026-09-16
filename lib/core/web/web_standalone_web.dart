import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('navigator.standalone')
external JSBoolean? get _iosStandalone;

/// True when this document is running as an installed app rather than a
/// browser tab.
///
/// Two checks are needed. `display-mode: standalone` is the standard, covering
/// Android WebAPKs and modern iOS. Older iOS Safari only reports installation
/// through the non-standard `navigator.standalone`, so it is read as a
/// fallback — never as the primary signal, since it is undefined elsewhere.
bool webIsInstalledApp() {
  try {
    if (web.window.matchMedia('(display-mode: standalone)').matches) {
      return true;
    }
  } catch (_) {}
  try {
    return _iosStandalone?.toDart ?? false;
  } catch (_) {
    return false;
  }
}
