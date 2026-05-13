import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecordingService {
  final Recorder _recorder = Recorder.instance;

  bool _hasMicPermission = false;
  bool _isRecorderReady = false;
  bool _isInitializing = false;
  bool _isRecording = false;
  String? _activeRecordingPath;

  static const Duration defaultRecordDuration = Duration(seconds: 5);

  Future<bool> initialize() async {
    if (_isInitializing) return false;
    if (_hasMicPermission && _isRecorderReady) return true;

    _isInitializing = true;

    try {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        _hasMicPermission = await Permission.microphone.request().isGranted;
      } else {
        _hasMicPermission = true;
      }

      if (!_hasMicPermission) {
        _isRecorderReady = false;
        return false;
      }

      await _recorder.init(
        format: PCMFormat.f32le,
        sampleRate: 16000,
        channels: RecorderChannels.mono,
      );
      _recorder.start();
      _isRecorderReady = true;
      return true;
    } catch (_) {
      _isRecorderReady = false;
      return false;
    } finally {
      _isInitializing = false;
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
      _recorder.startRecording(completeFilePath: filePath);
      _isRecording = true;

      await Future.delayed(duration);
      return await stopAndVerify();
    } catch (_) {
      await cancel();
      return null;
    }
  }

  Future<String?> stopAndVerify() async {
    if (!_isRecording) return null;

    try {
      _recorder.stopRecording();
      _isRecording = false;

      final finalPath = _activeRecordingPath;
      _activeRecordingPath = null;

      if (finalPath == null || finalPath.isEmpty) return null;

      final file = File(finalPath);
      await Future.delayed(const Duration(milliseconds: 200));

      if (!await file.exists()) return null;
      final fileSize = await file.length();

      return fileSize > 0 ? finalPath : null;
    } catch (_) {
      _isRecording = false;
      _activeRecordingPath = null;
      return null;
    }
  }

  Future<void> cancel() async {
    try {
      if (_isRecording) {
        _recorder.stopRecording();
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
    _recorder.deinit();
  }
}
