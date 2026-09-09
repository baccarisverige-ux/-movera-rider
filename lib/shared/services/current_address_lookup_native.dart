import 'package:geocoding/geocoding.dart';

Future<String?> reverseGeocodeCurrentPosition(
  double latitude,
  double longitude,
) async {
  final placemarks =
      await Geocoding().placemarkFromCoordinates(latitude, longitude);
  if (placemarks.isEmpty) return null;
  final place = placemarks.first;
  final parts = <String?>[
    place.street,
    place.postalCode,
    place.locality,
  ].whereType<String>().where((part) => part.trim().isNotEmpty).toList();
  return parts.isEmpty ? null : parts.join(', ');
}
