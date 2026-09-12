class DestinationRepository {
  static final instance = DestinationRepository();
  String? lastAddress;
  double? lastLat;
  double? lastLng;

  void remember({String? address, double? lat, double? lng}) {
    lastAddress = address ?? lastAddress;
    lastLat = lat ?? lastLat;
    lastLng = lng ?? lastLng;
  }
}
