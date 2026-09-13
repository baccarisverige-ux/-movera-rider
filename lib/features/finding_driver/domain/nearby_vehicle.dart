/// Available vehicle from matching. Positions come from the backend, never invented in UI.
class NearbyVehicle {
  const NearbyVehicle({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.bearing = 0,
  });

  final String id;
  final double latitude;
  final double longitude;
  final double bearing;

  static NearbyVehicle? fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final lat = (json['lat'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble();
    if (id.isEmpty || lat == null || lng == null) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    return NearbyVehicle(
      id: id,
      latitude: lat,
      longitude: lng,
      bearing: (json['bearing'] as num?)?.toDouble() ?? 0,
    );
  }
}
