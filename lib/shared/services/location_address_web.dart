import 'dart:convert';
import 'dart:js_interop';

class AddressCoordinates {
  const AddressCoordinates({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;
}

@JS('moveraReverseGeocode')
external JSPromise<JSString?> _reverseGeocode(
  JSNumber latitude,
  JSNumber longitude,
);

@JS('moveraGeocodeAddress')
external JSPromise<JSString?> _geocodeAddress(JSString address);

Future<String?> reverseGeocodeAddress(
  double latitude,
  double longitude,
) async {
  try {
    final result = await _reverseGeocode(
      latitude.toJS,
      longitude.toJS,
    ).toDart;
    return result?.toDart;
  } catch (_) {
    return null;
  }
}

Future<AddressCoordinates?> geocodeAddress(String address) async {
  try {
    final result = await _geocodeAddress(address.toJS).toDart;
    final raw = result?.toDart;
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return AddressCoordinates(
      address: json['address'] as String? ?? address,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  } catch (_) {
    return null;
  }
}
