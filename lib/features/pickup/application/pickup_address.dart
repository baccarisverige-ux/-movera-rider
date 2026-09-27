import 'package:google_maps_flutter/google_maps_flutter.dart';

String coordinatePickupAddress(LatLng position) =>
    '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

/// Confirmation must not wait on the network before closing the map picker.
String confirmedPickupAddress(String label, LatLng position) {
  final clean = label.trim();
  return clean.isEmpty || clean.toLowerCase() == 'current location'
      ? coordinatePickupAddress(position)
      : clean;
}

/// The UI may show "Current location", but the booking must identify a place.
Future<String> bookingPickupAddress({
  required String label,
  required LatLng position,
  required Future<String?> Function(LatLng) reverse,
}) async {
  final clean = label.trim();
  if (clean.isNotEmpty && clean.toLowerCase() != 'current location') {
    return clean;
  }
  try {
    final resolved = await reverse(position).timeout(const Duration(seconds: 8));
    if (resolved != null &&
        resolved.trim().isNotEmpty &&
        resolved.trim().toLowerCase() != 'current location') {
      return resolved.trim();
    }
  } catch (_) {
    // A usable coordinate is still safer than a UI-only placeholder.
  }
  return coordinatePickupAddress(position);
}
