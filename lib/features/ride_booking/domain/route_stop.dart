/// A stop between pickup and destination.
class RouteStop {
  const RouteStop({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final double latitude;
  final double longitude;

  Map<String, dynamic> toJson() => {
    'address': address,
    'lat': latitude,
    'lng': longitude,
  };

  static RouteStop? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final address = raw['address'];
    final lat = raw['lat'];
    final lng = raw['lng'];
    if (address is! String || lat is! num || lng is! num) return null;
    return RouteStop(
      address: address,
      latitude: lat.toDouble(),
      longitude: lng.toDouble(),
    );
  }

  static List<RouteStop> listFromJson(Object? raw) => [
    if (raw is List)
      for (final item in raw)
        if (fromJson(item) case final stop?) stop,
  ];

  @override
  bool operator ==(Object other) =>
      other is RouteStop &&
      other.address == address &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(address, latitude, longitude);
}
