abstract class LocationPickerRepository {
  Future<void> refresh();
}

class LocalLocationPickerRepository implements LocationPickerRepository {
  @override
  Future<void> refresh() async {}
}
