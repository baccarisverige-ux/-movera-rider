import 'package:movera_rider/core/location/place_search.dart';
import 'package:movera_rider/features/destination_search/data/destination_search_repository.dart';

class DestinationSearchController {
  DestinationSearchController(this._search);
  final PlaceSearchService _search;
  final _store = DestinationSearchRepository();

  void type(String value, void Function(String text) onReady) {
    _search.query(value, (text, generation) {
      if (!_search.isCurrent(generation)) return;
      _store.remember(text);
      onReady(text);
    });
  }
}
