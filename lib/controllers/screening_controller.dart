import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/screening_word_model.dart';
import '../services/audio_recording_service.dart';
import '../services/model_2_assessment_service.dart';

class ScreeningController extends ChangeNotifier {
  static const bool _useTestingWordLimit = true;
  static const int _testingWordsPerAge = 3;

  final int childAge;

  final AudioPlayer _player = AudioPlayer();
  final AudioRecordingService _recordingService = AudioRecordingService();
  final Model2AssessmentService _assessmentService = Model2AssessmentService();

  late final List<ScreeningWordModel> _words;
  final Map<String, String> _recordingsByWordId = {};
  final Map<String, Model2AssessmentResult> _assessmentResultsByWordId = {};

  int _currentIndex = 0;

  bool isRecording = false;
  bool isPromptPlaying = false;
  bool isProcessing = false;
  bool hasMicPermission = false;
  bool isRecorderReady = false;
  double recordingProgress = 0;
  int recordingCountdown = _autoRecordDuration.inSeconds;

  bool _isInitializingRecorder = false;
  int _recordingAttempt = 0;
  Timer? _recordingProgressTimer;

  String? errorMessage;

  StreamSubscription<PlayerState>? _playerStateSub;

  static const Duration _autoRecordDuration =
      AudioRecordingService.defaultRecordDuration;

  ScreeningController({required this.childAge}) {
    final resolvedWords = ScreeningWordModel.resolveForAge(childAge);
    // Testing only: set _useTestingWordLimit to false to restore full screening.
    _words = _useTestingWordLimit
        ? resolvedWords.take(_testingWordsPerAge).toList(growable: false)
        : resolvedWords;
    _init();
  }

  Future<void> _init() async {
    debugPrint('[screening] init child_age=$childAge words=${_words.length}');
    await _initRecorder();

    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      isPromptPlaying = state == PlayerState.playing;
      notifyListeners();
    });

    notifyListeners();
  }

  Future<void> _initRecorder() async {
    if (_isInitializingRecorder) return;
    if (isRecorderReady && hasMicPermission) return;

    _isInitializingRecorder = true;

    try {
      errorMessage = null;

      final ready = await _recordingService.initialize();
      hasMicPermission = _recordingService.hasMicPermission;
      isRecorderReady = ready;
      debugPrint(
        '[screening] recorder_init ready=$ready '
        'has_mic_permission=$hasMicPermission',
      );

      if (!ready) {
        errorMessage = hasMicPermission
            ? 'Recorder setup failed. Please try again.'
            : 'Microphone permission was denied.';
      }
    } catch (e) {
      isRecorderReady = false;
      errorMessage = 'Recorder setup failed: $e';
    } finally {
      _isInitializingRecorder = false;
      notifyListeners();
    }
  }

  List<ScreeningWordModel> get words => List.unmodifiable(_words);
  int get currentIndex => _currentIndex;
  int get currentStep => _currentIndex + 1;
  int get totalSteps => _words.length;
  bool get isLastWord => _currentIndex == _words.length - 1;
  ScreeningWordModel get currentWord => _words[_currentIndex];
  Map<String, String> get recordingsByWordId =>
      Map.unmodifiable(_recordingsByWordId);
  Map<String, Model2AssessmentResult> get assessmentResultsByWordId =>
      Map.unmodifiable(_assessmentResultsByWordId);

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
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> refreshPermission() async {
    hasMicPermission = false;
    isRecorderReady = false;
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
    debugPrint(
      '[screening] record_requested word=${currentWord.displayWord} '
      'word_id=${currentWord.id} can_record=$canRecord '
      'ready=$isRecorderReady mic=$hasMicPermission',
    );

    if (_isInitializingRecorder) return;

    if (!isRecorderReady || !hasMicPermission) {
      await _initRecorder();
    }

    if (!canRecord) return;

    clearError();
    isProcessing = true;
    recordingProgress = 0;
    recordingCountdown = _autoRecordDuration.inSeconds;
    notifyListeners();

    final word = currentWord;
    final wordId = word.id;
    final attempt = ++_recordingAttempt;

    try {
      await _player.stop();

      isRecording = true;
      isProcessing = false;
      recordingProgress = 0;
      recordingCountdown = _autoRecordDuration.inSeconds;
      notifyListeners();
      _startRecordingProgressTimer();

      final recordingPath = await _recordingService.recordTimed(
        fileNamePrefix: wordId,
        duration: _autoRecordDuration,
      );

      _stopRecordingProgressTimer();

      if (attempt != _recordingAttempt) return;

      isRecording = false;
      recordingProgress = 1;
      hasMicPermission = _recordingService.hasMicPermission;
      isRecorderReady = _recordingService.isRecorderReady;

      if (recordingPath != null) {
        _recordingsByWordId[wordId] = recordingPath;
        final recordingSize = await File(recordingPath).length();
        debugPrint(
          '[screening] recording_saved word_id=$wordId '
          'path=$recordingPath bytes=$recordingSize',
        );
        notifyListeners();

        isProcessing = true;
        notifyListeners();

        debugPrint(
          '[screening-api] immediate_assess_start word=${word.displayWord} '
          'word_id=$wordId path=$recordingPath '
          'base_url=${_assessmentService.baseUrl}',
        );
        final result = await _assessmentService.assess(
          word: word,
          recordingPath: recordingPath,
        );

        if (attempt != _recordingAttempt) return;

        _assessmentResultsByWordId[wordId] = result;
        if (result.isSuccess) {
          final score = result.overallScore?.toStringAsFixed(2);
          debugPrint(
            '[screening-api] immediate_assess_success '
            'word=${result.displayWord} word_id=${result.wordId} '
            'score=$score expected=${result.expectedIpa} '
            'detected=${result.detectedIpa} '
            'process_count=${result.detectedProcesses.length} '
            'processes=${result.detectedProcessSummary}',
          );
        } else {
          debugPrint(
            '[screening-api] immediate_assess_error '
            'word=${result.displayWord} word_id=${result.wordId} '
            'message=${result.error}',
          );
        }

        isProcessing = false;
      } else {
        errorMessage =
            'Recording was not saved as a valid WAV. Please try again.';
        recordingProgress = 0;
        recordingCountdown = _autoRecordDuration.inSeconds;
        debugPrint('[screening] recording_failed word_id=$wordId');
      }

      notifyListeners();
    } catch (e) {
      _stopRecordingProgressTimer();
      isRecording = false;
      isProcessing = false;
      recordingProgress = 0;
      recordingCountdown = _autoRecordDuration.inSeconds;
      errorMessage = 'Unable to start recording: $e';
      debugPrint('[screening] record_error word_id=$wordId error=$e');
      notifyListeners();
    }
  }

  void _startRecordingProgressTimer() {
    _stopRecordingProgressTimer();
    final startedAt = DateTime.now();
    _recordingProgressTimer = Timer.periodic(const Duration(milliseconds: 50), (
      _,
    ) {
      final elapsed = DateTime.now().difference(startedAt);
      final progress =
          elapsed.inMilliseconds / _autoRecordDuration.inMilliseconds;
      final remaining = _autoRecordDuration - elapsed;

      recordingProgress = progress.clamp(0, 1).toDouble();
      recordingCountdown = remaining.inMilliseconds <= 0
          ? 0
          : (remaining.inMilliseconds / 1000).ceil();
      notifyListeners();
    });
  }

  void _stopRecordingProgressTimer() {
    _recordingProgressTimer?.cancel();
    _recordingProgressTimer = null;
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;

    try {
      final finalPath = await _recordingService.stopAndVerify();
      _stopRecordingProgressTimer();
      isRecording = false;
      recordingProgress = 1;

      if (finalPath != null && finalPath.isNotEmpty) {
        final file = File(finalPath);

        await Future.delayed(const Duration(milliseconds: 200));

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

      notifyListeners();
    } catch (e) {
      _stopRecordingProgressTimer();
      isRecording = false;
      recordingProgress = 0;
      recordingCountdown = _autoRecordDuration.inSeconds;
      errorMessage = 'Failed to stop recording: $e';
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
      _assessmentResultsByWordId.remove(currentWord.id);
      recordingProgress = 0;
      recordingCountdown = _autoRecordDuration.inSeconds;
      errorMessage = null;
      notifyListeners();
    } catch (_) {
      errorMessage = 'Could not reset this recording.';
      notifyListeners();
    }
  }

  Future<bool> goNext() async {
    debugPrint(
      '[screening] next_requested current=${currentWord.displayWord} '
      'step=$currentStep/$totalSteps has_recording=$hasRecording '
      'saved_recordings=${_recordingsByWordId.length} '
      'model_results=${_assessmentResultsByWordId.length}',
    );

    if (isRecording) {
      errorMessage = 'Please wait for the recording to finish.';
      notifyListeners();
      return false;
    }

    if (isProcessing) {
      errorMessage = 'Please wait for the model result.';
      debugPrint(
        '[screening] next_blocked reason=model_processing '
        'word=${currentWord.displayWord} word_id=${currentWord.id}',
      );
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
      debugPrint(
        '[screening] moved_to_next step=$currentStep/$totalSteps '
        'word=${currentWord.displayWord}',
      );
      notifyListeners();
      return false;
    }

    debugPrint(
      '[screening] completed_all_words saved_recordings=${_recordingsByWordId.length} '
      'model_results=${_assessmentResultsByWordId.length} '
      'word_ids=${_recordingsByWordId.keys.join(',')}',
    );
    return true;
  }

  Future<void> cancelAndClearAll() async {
    try {
      _recordingAttempt++;

      if (isRecording) {
        await _recordingService.cancel();
      }

      await _player.stop();

      for (final path in _recordingsByWordId.values) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {
      // ignore cleanup errors
    } finally {
      _stopRecordingProgressTimer();
      _recordingsByWordId.clear();
      _assessmentResultsByWordId.clear();
      _currentIndex = 0;
      isRecording = false;
      isPromptPlaying = false;
      isProcessing = false;
      recordingProgress = 0;
      recordingCountdown = _autoRecordDuration.inSeconds;
      errorMessage = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _recordingAttempt++;
    _stopRecordingProgressTimer();
    _playerStateSub?.cancel();
    _player.dispose();
    unawaited(_recordingService.dispose());
    super.dispose();
  }
}
