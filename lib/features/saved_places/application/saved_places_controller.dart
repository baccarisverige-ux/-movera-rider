import 'package:movera_rider/features/saved_places/data/saved_places_repository.dart';
import 'package:movera_rider/features/saved_places/domain/saved_place.dart';
import 'package:movera_rider/shared/models/saved_places.dart';

class SavedPlacesController {
  SavedPlacesController({SavedPlacesRepository? store})
      : _store = store ?? SavedPlacesRepository();
  final SavedPlacesRepository _store;

  List<SavedPlacesModel> options() => _store.options();
  List<PlaceShortcut> shortcuts() => _store.shortcuts();
}
