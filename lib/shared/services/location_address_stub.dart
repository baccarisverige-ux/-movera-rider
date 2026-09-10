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

Future<String?> reverseGeocodeAddress(
  double latitude,
  double longitude,
) async {
  return null;
}

Future<AddressCoordinates?> geocodeAddress(String address) async {
  return null;
}
