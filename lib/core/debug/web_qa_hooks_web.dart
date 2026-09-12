import 'dart:js_interop';
import 'dart:js_interop_unsafe';

String? _firstSurface;
bool _homeBuilt = false;

void reportRestoreSurface(String surface) {
  globalContext.setProperty('moveraRestoreSurface'.toJS, surface.toJS);
  if (surface != 'hold') {
    _firstSurface ??= surface;
    globalContext.setProperty(
      'moveraFirstSurface'.toJS,
      _firstSurface!.toJS,
    );
  }
}

void reportHomeBuilt() {
  _homeBuilt = true;
  globalContext.setProperty('moveraHomeBuilt'.toJS, true.toJS);
}

void reportMapOwner(String? owner, int generation) {
  globalContext.setProperty('moveraMapOwner'.toJS, (owner ?? '').toJS);
  globalContext.setProperty('moveraMapGeneration'.toJS, generation.toJS);
}

void reportPuckHeading(double heading, {required bool compass}) {
  globalContext.setProperty('moveraPuckHeading'.toJS, heading.toJS);
  globalContext.setProperty('moveraCompassActive'.toJS, compass.toJS);
  try {
    final debug = globalContext.getProperty('moveraHeadingDebug'.toJS);
    if (debug.isUndefined || debug.isNull) return;
    final object = debug as JSObject;
    object.setProperty('dartHeading'.toJS, heading.toJS);
    object.setProperty('dartCompassActive'.toJS, compass.toJS);
    object.setProperty('puckHeading'.toJS, heading.toJS);
  } catch (_) {}
}

bool get debugHomeBuilt => _homeBuilt;
