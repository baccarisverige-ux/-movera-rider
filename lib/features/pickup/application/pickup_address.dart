import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Rider-facing label when no real address is known for a pickup point
/// (D-010). The coordinates themselves always travel separately
/// (pickupLat/pickupLng); a raw "lat, lng" string is never shown.
const String pickupLocationFallbackLabel = 'Pickup location';

String coordinatePickupAddress(LatLng position) =>
    '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

final RegExp _rawCoordinates = RegExp(
  r'^\s*-?\d{1,3}(\.\d+)?\s*,\s*-?\d{1,3}(\.\d+)?\s*$',
);

/// True for labels that do not name a place: empty, the UI-only
/// "Current location", or a raw coordinate string such as the demo
/// reverse-geocoder writes when it cannot produce an address.
bool isUnusablePickupLabel(String? label) {
  final clean = label?.trim() ?? '';
  return clean.isEmpty ||
      clean.toLowerCase() == 'current location' ||
      _rawCoordinates.hasMatch(clean);
}

/// Confirmation must not wait on the network before closing the map picker.
String confirmedPickupAddress(String label, LatLng position) {
  final clean = label.trim();
  return isUnusablePickupLabel(clean) ? pickupLocationFallbackLabel : clean;
}

/// The UI may show "Current location", but the booking should name a place
/// when one can be resolved; otherwise it uses [pickupLocationFallbackLabel]
/// (the booking's coordinates identify the point).
Future<String> bookingPickupAddress({
  required String label,
  required LatLng position,
  required Future<String?> Function(LatLng) reverse,
}) async {
  final clean = label.trim();
  if (!isUnusablePickupLabel(clean)) return clean;
  try {
    final resolved = await reverse(
      position,
    ).timeout(const Duration(seconds: 8));
    if (!isUnusablePickupLabel(resolved)) return resolved!.trim();
  } catch (_) {
    // Fall through to the rider-facing fallback label.
  }
  return pickupLocationFallbackLabel;
}
