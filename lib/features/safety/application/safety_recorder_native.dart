import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'safety_recorder_stub.dart';

export 'safety_recorder_stub.dart' show SafetyRecorder;

SafetyRecorder createSafetyRecorder() => NativeSafetyRecorder();

class NativeSafetyRecorder implements SafetyRecorder {
  AudioRecorder? _recorder;

  AudioRecorder get recorder => _recorder ??= AudioRecorder();

  @override
  bool get supported => true;

  // record.hasPermission requests the native microphone permission if needed.
  @override
  Future<bool> requestPermission() => recorder.hasPermission();

  @override
  Future<void> start(String recordingId) async {
    final directory = Directory(
      '${(await getApplicationDocumentsDirectory()).path}/safety_recordings',
    );
    await directory.create(recursive: true);
    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: '${directory.path}/$recordingId.m4a',
    );
  }

  @override
  Future<String?> stop() async {
    final path = await recorder.stop();
    if (path == null || !await File(path).exists() || await File(path).length() == 0) {
      return null;
    }
    return path;
  }

  @override
  Future<void> cancel() async {
    if (_recorder != null) await _recorder!.cancel();
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
