import 'package:movera_rider/features/safety/data/safety_store.dart';
import 'package:movera_rider/features/safety/domain/audio_recording.dart';
import 'safety_recorder.dart';

class SafetyAudioException implements Exception {
  const SafetyAudioException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'SafetyAudioException($code, $message)';
}

class SafetyAudioService {
  SafetyAudioService({
    SafetyRecorder? recorder,
    SafetyStore? store,
    this.supported = true,
  })  : _recorder = recorder ?? createSafetyRecorder(),
        _store = store ?? SafetyStore.shared;

  final SafetyRecorder _recorder;
  final SafetyStore _store;
  final bool supported;
  AudioRecording? _active;
  bool autoUpload = false;

  AudioRecording? get active => _active;
  bool get isRecording => _active?.isRecording == true;

  Future<AudioRecording> start({String rideId = 'ride_local'}) async {
    if (!supported || !_recorder.supported) {
      throw const SafetyAudioException(
        'UNSUPPORTED',
        'Audio recording is not available on this platform.',
      );
    }
    if (isRecording) {
      throw const SafetyAudioException('ALREADY_RECORDING', 'Already recording.');
    }
    if (!await _recorder.requestPermission()) {
      throw const SafetyAudioException(
        'MIC_DENIED',
        'Microphone permission is required to record.',
      );
    }
    final recording = await _store.initAudio(rideId);
    try {
      await _recorder.start(recording.id);
    } catch (_) {
      await _recorder.cancel();
      await _store.deleteAudio(recording);
      throw const SafetyAudioException(
        'START_FAILED',
        'Could not start microphone recording.',
      );
    }
    _active = recording.copyWith(
      createdAt: DateTime.now().toUtc(),
    );
    return _active!;
  }

  Future<AudioRecording> stop() async {
    final current = _active;
    if (current == null) {
      throw const SafetyAudioException('NOT_RECORDING', 'Nothing to stop.');
    }
    final ended = DateTime.now().toUtc();
    final started = current.createdAt ?? ended;
    final duration = ended.difference(started).inMilliseconds;
    final path = await _recorder.stop();
    _active = null;
    if (path == null) {
      throw const SafetyAudioException(
        'NO_AUDIO',
        'No audio file was captured.',
      );
    }
    AudioRecording next;
    try {
      next = await _store.completeAudio(
        current.copyWith(localPath: path, durationMs: duration, endedAt: ended),
      );
    } catch (_) {
      throw const SafetyAudioException(
        'SAVE_FAILED',
        'Audio was captured on this device, but its record could not be saved.',
      );
    }
    if (autoUpload) {
      throw const SafetyAudioException(
        'UPLOAD_DISABLED',
        'Automatic upload is not enabled.',
      );
    }
    return next;
  }

  Future<void> delete(AudioRecording recording) async {
    if (_active?.id == recording.id) {
      await _recorder.cancel();
      _active = null;
    }
    await _store.deleteAudio(recording);
    if (recording.localPath != null) {
      await _recorder.delete(recording.localPath!);
    }
  }
}
