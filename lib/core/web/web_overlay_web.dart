import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool _homeLockInstalled = false;

void webSetOverlayOpen(bool open) {
  html.document.body?.classes.toggle('movera-overlay-open', open);
}

void webSetHomeLock(bool lock) {
  _installHomeLock();
  html.document.documentElement?.classes.toggle('movera-home-lock', lock);
  final fn = globalContext.getProperty('moveraSetHomeLock'.toJS);
  if (fn.isA<JSFunction>()) {
    (fn as JSFunction).callAsFunction(globalContext, lock.toJS);
  }
}

void _installHomeLock() {
  if (_homeLockInstalled) return;
  _homeLockInstalled = true;
  try {
    html.document.documentElement?.style.setProperty(
      'overscroll-behavior-x',
      'none',
    );
    html.document.body?.style.setProperty('overscroll-behavior', 'none');
    html.document.body?.style.setProperty('overscroll-behavior-x', 'none');
  } catch (_) {}
  if (html.document.getElementById('movera-home-lock-js') != null) return;
  final script = html.ScriptElement()
    ..id = 'movera-home-lock-js'
    ..text = r'''
(function() {
  if (history.scrollRestoration) history.scrollRestoration = 'manual';
  window._moveraHomeLock = false;
  window.moveraSetHomeLock = function(lock) {
    window._moveraHomeLock = !!lock;
    try {
      document.documentElement.classList.toggle('movera-home-lock', !!lock);
    } catch (_) {}
    if (lock) {
      try { history.replaceState({ moveraHome: 1 }, '', location.href); } catch (_) {}
    }
  };
  window.addEventListener('popstate', function() {
    if (!window._moveraHomeLock) return;
    try { history.pushState({ moveraHome: 1 }, '', location.href); } catch (_) {}
  });
})();
''';
  html.document.head?.append(script);
}
