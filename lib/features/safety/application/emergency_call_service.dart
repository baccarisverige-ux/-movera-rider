/// Opens the system dialer. Never invoked automatically.
abstract class EmergencyDialer {
  Future<void> open(String number);
}

class RecordingEmergencyDialer implements EmergencyDialer {
  final calls = <String>[];

  @override
  Future<void> open(String number) async {
    calls.add(number);
  }
}

class EmergencyCallService {
  EmergencyCallService({EmergencyDialer? dialer})
      : _dialer = dialer ?? RecordingEmergencyDialer();

  static const swedenEmergencyNumber = '112';

  final EmergencyDialer _dialer;
  int _explicitCalls = 0;

  int get explicitCallCount => _explicitCalls;
  EmergencyDialer get dialer => _dialer;

  /// Requires an explicit rider action. Never called from background logic.
  Future<void> callEmergencyNumber() async {
    _explicitCalls += 1;
    await _dialer.open(swedenEmergencyNumber);
  }
}
