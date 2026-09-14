import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

bool _homeLockInstalled = false;

void webSetOverlayOpen(bool open) {
  web.document.body?.classList.toggle('movera-overlay-open', open);
}

void webSetHomeLock(bool lock) {
  _installHomeLock();
  web.document.documentElement?.classList.toggle('movera-home-lock', lock);
  final fn = globalContext.getProperty('moveraSetHomeLock'.toJS);
  if (fn.isA<JSFunction>()) {
    (fn as JSFunction).callAsFunction(globalContext, lock.toJS);
  }
}

void _installHomeLock() {
  if (_homeLockInstalled) return;
  _homeLockInstalled = true;
  try {
    (web.document.documentElement as web.HTMLElement?)?.style.setProperty(
      'overscroll-behavior-x',
      'none',
    );
    web.document.body?.style.setProperty('overscroll-behavior', 'none');
    web.document.body?.style.setProperty('overscroll-behavior-x', 'none');
  } catch (_) {}
  if (web.document.getElementById('movera-home-lock-js') != null) return;
  final script = web.document.createElement('script') as web.HTMLScriptElement
    ..id = 'movera-home-lock-js'
    ..text = r'''
(function() {
  // The pushState/popstate sentinel below exists to stop a browser TAB's
  // address-bar swipe-back gesture from treating Home sheet overscroll as
  // history.back. An installed standalone PWA (Android "Add to Home
  // Screen") has no address bar and a different back-gesture model, so
  // that premise doesn't hold there -- and phantom history entries plus a
  // global popstate interceptor is exactly the kind of thing that can
  // misbehave in a navigation context it wasn't built for. Skip it when
  // running standalone; still toggle the CSS lock class either way.
  var isStandalone = false;
  try {
    isStandalone = !!(window.matchMedia &&
      window.matchMedia('(display-mode: standalone)').matches);
  } catch (_) {}

  if (history.scrollRestoration) history.scrollRestoration = 'manual';
  window._moveraHomeLock = false;
  window._moveraHomeSentinel = false;
  window.moveraSetHomeLock = function(lock) {
    window._moveraHomeLock = !!lock;
    try {
      document.documentElement.classList.toggle('movera-home-lock', !!lock);
    } catch (_) {}
    if (isStandalone) return;
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
  if (!isStandalone) {
    window.addEventListener('popstate', function() {
      if (!window._moveraHomeLock) return;
      try { history.pushState({ moveraHome: 1 }, '', location.href); } catch (_) {}
    });
  }
})();
''';
  web.document.head?.appendChild(script);
}
