import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();

  bool _hasMicPermission = false;
  bool _isRecorderReady = false;
  Future<bool>? _initializeFuture;
  bool _isRecording = false;
  String? _activeRecordingPath;

  static const int sampleRate = 16000;
  static const int channelCount = 1;
  static const Duration defaultRecordDuration = Duration(seconds: 3);

  static const RecordConfig _wav16kMonoConfig = RecordConfig(
    encoder: AudioEncoder.wav,
    sampleRate: sampleRate,
    numChannels: channelCount,
  );

  bool get hasMicPermission => _hasMicPermission;
  bool get isRecorderReady => _isRecorderReady;
  bool get isRecording => _isRecording;
  Stream<double> get amplitudeLevels => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 80))
      .map((amplitude) => ((amplitude.current + 55) / 50).clamp(0.0, 1.0));

  Future<bool> initialize() async {
    if (_hasMicPermission && _isRecorderReady) return true;
    _initializeFuture ??= _initializeRecorder();

    try {
      return await _initializeFuture!;
    } finally {
      _initializeFuture = null;
    }
  }

  Future<bool> _initializeRecorder() async {
    try {
      _hasMicPermission = await _recorder.hasPermission();
      if (!_hasMicPermission) {
        _isRecorderReady = false;
        debugPrint('[audio-recording] init_denied microphone_permission=false');
        return false;
      }

      _isRecorderReady = true;
      debugPrint('[audio-recording] init_ready microphone_permission=true');
      return true;
    } catch (error) {
      debugPrint('[audio-recording] init_error error=$error');
      _hasMicPermission = false;
      _isRecorderReady = false;
      return false;
    }
  }

  Future<String?> recordTimed({
    required String fileNamePrefix,
    Duration duration = defaultRecordDuration,
  }) async {
    final ready = await initialize();
    if (!ready || _isRecording) return null;

    try {
      final tempDir = await getTemporaryDirectory();
      final safePrefix = fileNamePrefix.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );
      final filePath =
          '${tempDir.path}/${safePrefix}_${DateTime.now().millisecondsSinceEpoch}.wav';

      _activeRecordingPath = filePath;
      debugPrint(
        '[audio-recording] start path=$filePath '
        'encoder=wav sample_rate=$sampleRate channels=$channelCount '
        'duration_ms=${duration.inMilliseconds}',
      );
      await _recorder.start(_wav16kMonoConfig, path: filePath);
      _isRecording = true;

      await Future.delayed(duration);
      return await stopAndVerify();
    } catch (error) {
      debugPrint('[audio-recording] start_error error=$error');
      await cancel();
      return null;
    }
  }

  Future<String?> stopAndVerify() async {
    final recorderIsRecording = await _recorder.isRecording();
    if (!_isRecording && !recorderIsRecording) return null;

    try {
      final stoppedPath = await _recorder.stop();
      _isRecording = false;

      final finalPath = stoppedPath ?? _activeRecordingPath;
      _activeRecordingPath = null;

      if (finalPath == null || finalPath.isEmpty) return null;

      final file = File(finalPath);
      await Future.delayed(const Duration(milliseconds: 200));

      if (!await file.exists()) return null;
      final fileSize = await file.length();

      debugPrint(
        '[audio-recording] stop_valid path=$finalPath bytes=$fileSize',
      );

      return finalPath;
    } catch (error) {
      debugPrint('[audio-recording] stop_error error=$error');
      _isRecording = false;
      _activeRecordingPath = null;
      return null;
    }
  }

  Future<void> cancel() async {
    try {
      final recorderIsRecording = await _recorder.isRecording();
      if (_isRecording || recorderIsRecording) {
        await _recorder.cancel();
      }

      final activePath = _activeRecordingPath;
      if (activePath != null) {
        final file = File(activePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {
      // Ignore cleanup errors while leaving the screen.
    } finally {
      _isRecording = false;
      _activeRecordingPath = null;
    }
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }
}
