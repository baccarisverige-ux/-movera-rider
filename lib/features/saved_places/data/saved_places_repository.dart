abstract class SavedPlacesRepository {
  Future<void> refresh();
}

class LocalSavedPlacesRepository implements SavedPlacesRepository {
  @override
  Future<void> refresh() async {}
}
