import 'package:movera_rider/features/ride_history/data/ride_history_repository.dart';
import 'package:movera_rider/features/ride_history/domain/ride_history.dart';

class RideHistoryController {
  RideHistoryController({RideHistoryRepository? store})
      : _store = store ?? RideHistoryRepository();
  final RideHistoryRepository _store;

  List<RideHistoryItem> past() => _store.past();
}
