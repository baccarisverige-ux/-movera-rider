abstract class SafetyRecorder {
  bool get supported;
  Future<bool> requestPermission();
  Future<void> start(String recordingId);
  Future<String?> stop();
  Future<void> cancel();
  Future<void> delete(String path);
}

SafetyRecorder createSafetyRecorder() => const UnsupportedSafetyRecorder();

class UnsupportedSafetyRecorder implements SafetyRecorder {
  const UnsupportedSafetyRecorder();

  @override
  bool get supported => false;
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> start(String recordingId) async =>
      throw UnsupportedError('Audio recording is unavailable on this platform.');
  @override
  Future<String?> stop() async => null;
  @override
  Future<void> cancel() async {}
  @override
  Future<void> delete(String path) async {}
}
