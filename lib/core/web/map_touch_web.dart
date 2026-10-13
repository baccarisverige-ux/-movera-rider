import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:movera_rider/core/web/map_touch.dart';
import 'package:web/web.dart' as web;

class _DocumentListeners implements MapTouchSubscription {
  _DocumentListeners(this._handlers) {
    for (final (type, handler) in _handlers) {
      web.document.addEventListener(type, handler, true.toJS);
    }
  }

  final List<(String, web.EventListener)> _handlers;

  @override
  void cancel() {
    for (final (type, handler) in _handlers) {
      web.document.removeEventListener(type, handler, true.toJS);
    }
  }
}

bool _onGoogleMap(web.Event event) {
  final target = event.target;
  if (target == null || !target.isA<web.Element>()) return false;
  return (target as web.Element).closest('.gm-style') != null;
}

MapTouchSubscription? watchWebMapTouch({
  required VoidCallback onDown,
  required VoidCallback onUp,
}) {
  final down = ((web.Event event) {
    if (_onGoogleMap(event)) onDown();
  }).toJS;
  final up = ((web.Event event) => onUp()).toJS;
  // Capture phase: the map stops some of these from bubbling.
  return _DocumentListeners([
    ('pointerdown', down),
    ('pointerup', up),
    ('pointercancel', up),
  ]);
}
