import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:movera_rider/core/web/web_standalone.dart';
import 'package:web/web.dart' as web;

bool _homeLockInstalled = false;

void webSetOverlayOpen(bool open) {
  web.document.body?.classList.toggle('movera-overlay-open', open);
}

void webSetHomeLock(bool lock) {
  _applyHomeLockCss(lock);

  // Browser tabs need a history sentinel so a horizontal overscroll on Home
  // does not become history.back. Installed Home Screen apps do not have that
  // browser-navigation model. On iOS, relying only on display-mode can miss the
  // installed state, while navigator.standalone is still true. Use the shared
  // detector here so standalone never gets phantom history entries that can
  // desynchronise Flutter navigation (Finding, Cancel, modal sheets, Wallet).
  if (isInstalledWebApp()) return;

  _installHomeLock();
  final fn = globalContext.getProperty('moveraSetHomeLock'.toJS);
  if (fn.isA<JSFunction>()) {
    (fn as JSFunction).callAsFunction(globalContext, lock.toJS);
  }
}

void _applyHomeLockCss(bool lock) {
  web.document.documentElement?.classList.toggle('movera-home-lock', lock);
  try {
    (web.document.documentElement as web.HTMLElement?)?.style.setProperty(
      'overscroll-behavior-x',
      'none',
    );
    web.document.body?.style.setProperty('overscroll-behavior', 'none');
    web.document.body?.style.setProperty('overscroll-behavior-x', 'none');
  } catch (_) {}
}

void _installHomeLock() {
  if (_homeLockInstalled) return;
  _homeLockInstalled = true;
  if (web.document.getElementById('movera-home-lock-js') != null) return;
  final script = web.document.createElement('script') as web.HTMLScriptElement
    ..id = 'movera-home-lock-js'
    ..text = r'''
(function() {
  // This sentinel is browser-tab-only. Dart checks the shared installed-app
  // detector before this script is installed, so there is no second,
  // potentially inconsistent standalone detector here.
  if (history.scrollRestoration) history.scrollRestoration = 'manual';
  window._moveraHomeLock = false;
  window._moveraHomeSentinel = false;
  window.moveraSetHomeLock = function(lock) {
    window._moveraHomeLock = !!lock;
    try {
      document.documentElement.classList.toggle('movera-home-lock', !!lock);
    } catch (_) {}
    if (!lock) {
      window._moveraHomeSentinel = false;
      return;
    }
    if (window._moveraHomeSentinel) return;
    window._moveraHomeSentinel = true;
    try {
      history.replaceState({ moveraHome: 1 }, '', location.href);
      history.pushState({ moveraHome: 1 }, '', location.href);
    } catch (_) {}
  };
  window.addEventListener('popstate', function() {
    if (!window._moveraHomeLock) return;
    try { history.pushState({ moveraHome: 1 }, '', location.href); } catch (_) {}
  });
})();
''';
  web.document.head?.appendChild(script);
}
