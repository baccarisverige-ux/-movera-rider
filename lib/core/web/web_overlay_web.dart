import 'dart:html' as html;

void webSetOverlayOpen(bool open) {
  html.document.body?.classes.toggle('movera-overlay-open', open);
}
