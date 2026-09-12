import 'dart:js_interop';

@JS('moveraStartHeading')
external JSPromise<JSBoolean> _startHeading();

@JS('moveraStopHeading')
external void _stopHeading();

@JS('moveraDeviceHeading')
external JSNumber? get _heading;

Future<bool> startHeadingTracking() async {
  try {
    return (await _startHeading().toDart).toDart;
  } catch (_) {
    return false;
  }
}

double? currentHeading() {
  try {
    return _heading?.toDartDouble;
  } catch (_) {
    return null;
  }
}

void stopHeadingTracking() {
  try {
    _stopHeading();
  } catch (_) {}
}
