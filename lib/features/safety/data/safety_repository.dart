import 'package:movera_rider/features/safety/domain/safety_event.dart';

class SafetyRepository {
  final events = <SafetyEvent>[];

  void add(SafetyEvent event) => events.add(event);
}
