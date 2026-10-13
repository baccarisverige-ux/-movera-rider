import 'package:google_maps_flutter/google_maps_flutter.dart';

/// What kind of pickup spot a chip stands for; picks its icon.
enum PickupSpotKind { entrance, parking, previous, home }

/// A suggested place to meet the driver near the pickup address.
class PickupSpot {
  const PickupSpot({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.position,
  });

  final String id;
  final String title;
  final String subtitle;
  final PickupSpotKind kind;
  final LatLng position;
}

/// A pickup the rider confirmed earlier; the source of "Previously used".
class PreviousPickup {
  const PreviousPickup({
    required this.position,
    required this.address,
    required this.savedAt,
  });

  final LatLng position;
  final String address;
  final DateTime savedAt;
}

/// Where confirmed pickups are kept. The data layer backs it with
/// SharedPreferences; tests use an in-memory one.
abstract class PreviousPickupsStore {
  Future<List<PreviousPickup>> read();
  Future<void> write(List<PreviousPickup> pickups);
}
