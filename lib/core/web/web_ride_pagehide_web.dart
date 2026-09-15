import 'dart:js_interop';

import 'package:movera_rider/core/web/web_ride_pagehide_policy.dart';
import 'package:web/web.dart' as web;

bool _installed = false;

void webInstallRidePagehide(void Function() onPageHide) {
  if (_installed) return;
  _installed = true;
  web.window.addEventListener(
    'pagehide',
    (web.Event event) {
      final pageEvent = event as web.PageTransitionEvent;
      if (shouldHandleRidePageHide(persisted: pageEvent.persisted)) {
        onPageHide();
      }
    }.toJS,
  );
}
