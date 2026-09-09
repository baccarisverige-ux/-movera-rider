@JS()
library;

import 'dart:js' as js;
import 'dart:js_util' as js_util;

Future<String?> reverseGeocodeCurrentPosition(
  double latitude,
  double longitude,
) async {
  final promise = js.context.callMethod<Object>(
    'moveraReverseGeocode',
    [latitude, longitude],
  );
  final result = await js_util.promiseToFuture<Object?>(promise);
  return result?.toString();
}
