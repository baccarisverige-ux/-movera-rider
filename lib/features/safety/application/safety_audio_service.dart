import 'package:movera_rider/core/permissions/permission_service.dart';
import 'package:movera_rider/features/safety/data/safety_store.dart';
import 'package:movera_rider/features/safety/domain/audio_recording.dart';

class SafetyAudioException implements Exception {
  const SafetyAudioException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'SafetyAudioException($code, $message)';
}

class SafetyAudioService {
  SafetyAudioService({
    PermissionService? permissions,
    SafetyStore? store,
    this.supported = true,
  })  : _permissions = permissions ?? PermissionService(),
        _store = store ?? SafetyStore.shared;

  final PermissionService _permissions;
  final SafetyStore _store;
  final bool supported;
  AudioRecording? _active;
  bool autoUpload = false;

  AudioRecording? get active => _active;
  bool get isRecording => _active?.isRecording == true;

  Future<AudioRecording> start({String rideId = 'ride_local'}) async {
    if (!supported) {
      throw const SafetyAudioException(
        'UNSUPPORTED',
        'Audio recording is not available in this browser.',
      );
    }
    if (_permissions.statusOf(AppPermission.microphone) !=
        PermissionPhase.granted) {
      throw const SafetyAudioException(
        'MIC_DENIED',
        'Microphone permission is required to record.',
      );
    }
    if (isRecording) {
      throw const SafetyAudioException('ALREADY_RECORDING', 'Already recording.');
    }
    final recording = await _store.initAudio(rideId);
    _active = recording.copyWith(
      localPath: 'local://safety/${recording.id}.m4a',
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
    final next = await _store.completeAudio(
      current.copyWith(durationMs: duration, endedAt: ended),
    );
    _active = null;
    if (autoUpload) {
      throw const SafetyAudioException(
        'UPLOAD_DISABLED',
        'Automatic upload is not enabled.',
      );
    }
    return next;
  }

  Future<void> delete(AudioRecording recording) async {
    if (_active?.id == recording.id) _active = null;
    await _store.deleteAudio(recording);
  }

  void grantMicrophone() {
    _permissions.set(AppPermission.microphone, PermissionPhase.granted);
  }

  void denyMicrophone() {
    _permissions.set(AppPermission.microphone, PermissionPhase.denied);
  }
}
