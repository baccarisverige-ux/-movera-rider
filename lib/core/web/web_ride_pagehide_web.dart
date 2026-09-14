import 'dart:html' as html;

bool _installed = false;

void webInstallRidePagehide(void Function() onPageHide) {
  if (_installed) return;
  _installed = true;
  html.window.addEventListener('pagehide', (_) => onPageHide());
}
