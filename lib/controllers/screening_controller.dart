import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_recorder/flutter_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/screening_word_model.dart';

class ScreeningController extends ChangeNotifier {
  final int childAge;

  final AudioPlayer _player = AudioPlayer();
  final Recorder _recorder = Recorder.instance;

  late final List<ScreeningWordModel> _words;
  final Map<String, String> _recordingsByWordId = {};

  int _currentIndex = 0;

  bool isRecording = false;
  bool isPromptPlaying = false;
  bool isProcessing = false;
  bool hasMicPermission = false;
  bool isRecorderReady = false;

  String? _activeRecordingPath;
  String? errorMessage;

  Timer? _autoStopTimer;
  StreamSubscription<PlayerState>? _playerStateSub;

  static const Duration _autoRecordDuration = Duration(seconds: 3);

  ScreeningController({required this.childAge}) {
    _words = ScreeningWordModel.resolveForAge(childAge);
    _init();
  }

  Future<void> _init() async {
    await _initRecorder();

    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      isPromptPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> _initRecorder() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final granted = await Permission.microphone.request().isGranted;
        hasMicPermission = granted;
      } else {
        hasMicPermission = true;
      }

      if (!hasMicPermission) {
        errorMessage = 'Microphone permission was denied.';
        notifyListeners();
        return;
      }

      await _recorder.init(
        format: PCMFormat.f32le,
        sampleRate: 16000,
        channels: RecorderChannels.mono,
      );

      _recorder.start();
      isRecorderReady = true;
    } catch (_) {
      isRecorderReady = false;
      errorMessage = 'Recorder setup failed.';
      notifyListeners();
    }
  }

  List<ScreeningWordModel> get words => List.unmodifiable(_words);
  int get currentIndex => _currentIndex;
  int get currentStep => _currentIndex + 1;
  int get totalSteps => _words.length;
  bool get isLastWord => _currentIndex == _words.length - 1;
  ScreeningWordModel get currentWord => _words[_currentIndex];

  bool get hasRecording => _recordingsByWordId.containsKey(currentWord.id);
  String? get currentRecordingPath => _recordingsByWordId[currentWord.id];

  bool get canPlayPrompt => !isPromptPlaying && !isRecording && !isProcessing;
  bool get canRecord =>
      hasMicPermission &&
      isRecorderReady &&
      !isPromptPlaying &&
      !isRecording &&
      !isProcessing;

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshPermission() async {
    await _initRecorder();
  }

  Future<void> playPromptAudio() async {
    if (!canPlayPrompt) return;

    clearError();

    try {
      await _player.stop();
      await _player.play(AssetSource(currentWord.audioAssetPath));
    } catch (_) {
      errorMessage = 'Could not play the prompt audio.';
      notifyListeners();
    }
  }

  Future<void> startTimedRecording() async {
    if (!canRecord) return;

    clearError();
    isProcessing = true;
    notifyListeners();

    try {
      await _player.stop();

      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/${currentWord.id}_${DateTime.now().millisecondsSinceEpoch}.wav';

      _activeRecordingPath = filePath;

      _recorder.startRecording(completeFilePath: filePath);

      isRecording = true;
      isProcessing = false;
      notifyListeners();

      _autoStopTimer?.cancel();
      _autoStopTimer = Timer(_autoRecordDuration, () async {
        await stopRecording();
      });
    } catch (_) {
      isRecording = false;
      isProcessing = false;
      _activeRecordingPath = null;
      errorMessage = 'Unable to start recording.';
      notifyListeners();
    }
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;

    try {
      _autoStopTimer?.cancel();
      _autoStopTimer = null;

      _recorder.stopRecording();

      isRecording = false;

      final finalPath = _activeRecordingPath;
      if (finalPath != null && finalPath.isNotEmpty) {
        final file = File(finalPath);

        // Give the file system a moment to finalize the WAV file.
        await Future.delayed(const Duration(milliseconds: 150));

        if (await file.exists()) {
          final size = await file.length();

          if (size > 1024) {
            _recordingsByWordId[currentWord.id] = finalPath;
          } else {
            errorMessage = 'Recording was too short. Please try again.';
          }
        } else {
          errorMessage = 'Recording file was not created properly.';
        }
      } else {
        errorMessage = 'No recording was captured.';
      }

      _activeRecordingPath = null;
      notifyListeners();
    } catch (_) {
      _autoStopTimer?.cancel();
      _autoStopTimer = null;
      isRecording = false;
      _activeRecordingPath = null;
      errorMessage = 'Failed to stop recording.';
      notifyListeners();
    }
  }

  Future<void> repeatCurrentWord() async {
    try {
      if (isRecording) {
        await stopRecording();
      }

      await _player.stop();

      final existingPath = _recordingsByWordId[currentWord.id];
      if (existingPath != null) {
        final file = File(existingPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      _recordingsByWordId.remove(currentWord.id);
      errorMessage = null;
      notifyListeners();
    } catch (_) {
      errorMessage = 'Could not reset this recording.';
      notifyListeners();
    }
  }

  Future<bool> goNext() async {
    if (isRecording) {
      errorMessage = 'Please wait for the recording to finish.';
      notifyListeners();
      return false;
    }

    if (!hasRecording) {
      errorMessage = 'Please record the word first.';
      notifyListeners();
      return false;
    }

    if (!isLastWord) {
      _currentIndex++;
      errorMessage = null;
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<void> cancelAndClearAll() async {
    try {
      _autoStopTimer?.cancel();
      _autoStopTimer = null;

      if (isRecording) {
        _recorder.stopRecording();
      }

      await _player.stop();

      for (final path in _recordingsByWordId.values) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }

      if (_activeRecordingPath != null) {
        final activeFile = File(_activeRecordingPath!);
        if (await activeFile.exists()) {
          await activeFile.delete();
        }
      }
    } catch (_) {
      // ignore cleanup errors
    } finally {
      _recordingsByWordId.clear();
      _activeRecordingPath = null;
      _currentIndex = 0;
      isRecording = false;
      isPromptPlaying = false;
      isProcessing = false;
      errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _playerStateSub?.cancel();
    _player.dispose();
    _recorder.deinit();
    super.dispose();
  }
}
