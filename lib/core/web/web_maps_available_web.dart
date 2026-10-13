import 'dart:js_interop';
import 'dart:js_interop_unsafe';

bool webGoogleMapsAvailable() {
  final google = globalContext.getProperty<JSAny?>('google'.toJS);
  if (google == null || !google.isA<JSObject>()) return false;
  final maps = (google as JSObject).getProperty<JSAny?>('maps'.toJS);
  return maps != null && maps.isA<JSObject>();
}
