import 'package:movera_rider/features/ride_selection/data/ride_selection_repository.dart';
import 'package:movera_rider/features/ride_selection/domain/ride_selection.dart';

class RideSelectionController {
  RideSelectionController({RideSelectionRepository? store})
      : _store = store ?? RideSelectionRepository();
  final RideSelectionRepository _store;

  List<RideCatalogItem> rides() => _store.rides();
  List<RidePaymentItem> payments() => _store.payments();
}
