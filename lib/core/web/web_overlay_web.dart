import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

void webSetOverlayOpen(bool open) {
  html.document.body?.classes.toggle('movera-overlay-open', open);
}

void webSetHomeLock(bool lock) {
  html.document.documentElement?.classes.toggle('movera-home-lock', lock);
  final fn = globalContext.getProperty('moveraSetHomeLock'.toJS);
  if (fn.isA<JSFunction>()) {
    (fn as JSFunction).callAsFunction(globalContext, lock.toJS);
  }
}
