import 'package:movera_rider/features/safety/domain/safety_event.dart';

/// In-process safety event log used by Waiting (`maskedCall`) and SOS.
/// Extended, not replaced. Shared so `SafetyController().record` keeps events.
class SafetyRepository {
  SafetyRepository();

  static SafetyRepository? _shared;
  static SafetyRepository get shared => _shared ??= SafetyRepository();

  static void resetShared() => _shared = null;

  final events = <SafetyEvent>[];

  void add(SafetyEvent event) => events.add(event);
}
