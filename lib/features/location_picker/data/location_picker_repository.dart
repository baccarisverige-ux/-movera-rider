class LocationPickerRepository {
  double? lastLat;
  double? lastLng;
  void remember(double lat, double lng) {
    lastLat = lat;
    lastLng = lng;
  }
}
