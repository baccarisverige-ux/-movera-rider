import 'package:movera_rider/features/support/data/support_repository.dart';
import 'package:movera_rider/features/support/domain/support.dart';

class SupportController {
  SupportController({SupportRepository? store})
      : _store = store ?? SupportRepository();
  final SupportRepository _store;

  List<SupportRide> rides() => _store.rides();
  SupportChatScript chat({SupportRide? ride}) => _store.chat(ride: ride);
}
