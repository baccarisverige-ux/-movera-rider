import 'package:movera_rider/features/location_picker/data/location_picker_repository.dart';

class LocationPickerController {
  LocationPickerController({LocationPickerRepository? store})
      : _store = store ?? LocationPickerRepository();
  final LocationPickerRepository _store;

  void remember(double lat, double lng) => _store.remember(lat, lng);
}
