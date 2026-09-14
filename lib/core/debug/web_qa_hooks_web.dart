import 'package:movera_rider/core/debug/movera_qa.dart';
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

void reportSafetySnapshot(String json) {
  globalContext.setProperty('moveraSafetySnapshotJson'.toJS, json.toJS);
}

void installSafetyQaOpener(void Function() open) {
  if (!moveraQaHooksEnabled) return;
  globalContext.setProperty(
    'moveraOpenSafety'.toJS,
    (() {
      try {
        open();
        return 'ok'.toJS;
      } catch (_) {
        return 'error'.toJS;
      }
    }).toJS,
  );
}

void reportSearchSnapshot(String json) {
  globalContext.setProperty('moveraSearchSnapshotJson'.toJS, json.toJS);
}

void installMatchingQaHooks({
  required void Function() hold,
  required void Function() assign,
  required void Function(int seconds) advance,
}) {
  if (!moveraQaHooksEnabled) return;
  globalContext.setProperty(
    'moveraHoldMatching'.toJS,
    (() {
      try {
        hold();
        return 'ok'.toJS;
      } catch (_) {
        return 'error'.toJS;
      }
    }).toJS,
  );
  globalContext.setProperty(
    'moveraAssignDriver'.toJS,
    (() {
      try {
        assign();
        return 'ok'.toJS;
      } catch (_) {
        return 'error'.toJS;
      }
    }).toJS,
  );
  globalContext.setProperty(
    'moveraAdvanceSearch'.toJS,
    ((JSNumber seconds) {
      try {
        advance(seconds.toDartDouble.round());
        return 'ok'.toJS;
      } catch (_) {
        return 'error'.toJS;
      }
    }).toJS,
  );
}

String? pendingRideCheckType() {
  try {
    final value = globalContext.getProperty('_moveraPendingRideCheck'.toJS);
    if (value.isUndefined || value.isNull) return null;
    return (value as JSString).toDart;
  } catch (_) {
    return null;
  }
}

void clearPendingRideCheck() {
  globalContext.setProperty('_moveraPendingRideCheck'.toJS, null);
}
