import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../gamescene/game_scene_state.dart';
import '../../../services/model_2_assessment_service.dart';
import '../domain/game_level_config.dart';
import '../domain/game_level_kind.dart';
import '../domain/game_result.dart';
import 'game_services.dart';
import 'game_session_state.dart';

part 'game_session_flow.dart';
part 'game_session_scene_mapper.dart';

class GameSessionTimings {
  final Duration recordingDuration;
  final Duration levelCaptionDuration;
  final Duration targetCaptionDuration;
  final Duration feedbackHold;
  final Duration successHold;

  const GameSessionTimings({
    this.recordingDuration = const Duration(seconds: 3),
    this.levelCaptionDuration = const Duration(milliseconds: 1500),
    this.targetCaptionDuration = const Duration(milliseconds: 1400),
    this.feedbackHold = const Duration(milliseconds: 900),
    this.successHold = const Duration(milliseconds: 1300),
  });
}

class GameSessionController extends ChangeNotifier {
  final GameLevelConfig config;
  final GameRecorder _recorder;
  final GameAssessmentClient _assessmentClient;
  final GameSessionTimings timings;
  final ValueNotifier<GameResult?> completionResult = ValueNotifier(null);

  late GameSessionState _state;
  Timer? _recordingCountdownTimer;
  int _operationToken = 0;
  bool _flowRunning = false;
  bool _levelCaptionShown = false;
  bool _paused = false;
  bool _disposed = false;

  static const double passingScore = 80;
  static const int maxRetriesPerTarget = 2;

  GameSessionController({
    required this.config,
    required GameRecorder recorder,
    required GameAssessmentClient assessmentClient,
    this.timings = const GameSessionTimings(),
  }) : _recorder = recorder,
       _assessmentClient = assessmentClient {
    _state = GameSessionState.initial(config: config);
  }

  factory GameSessionController.createDefault(GameLevelConfig config) {
    return GameSessionController(
      config: config,
      recorder: AudioGameRecorder(),
      assessmentClient: Model2GameAssessmentClient(),
    );
  }

  GameSessionState get state => _state;

  void start() {
    if (_disposed || _flowRunning) return;
    unawaited(_prepareAndStart());
  }

  void retryCurrent() {
    if (_disposed || _flowRunning || !_state.canRetry) return;
    unawaited(_prepareAndStart());
  }

  void finishLevel() {
    if (_disposed || !_state.isComplete || completionResult.value != null) {
      return;
    }

    completionResult.value = GameResult(
      levelIndex: config.levelIndex,
      correct: true,
      accuracy: _state.averageAccuracy(),
      attemptedTargetCount: _state.targetAccuracies.length,
      needsPracticeCount: _state.needsPracticeTargetIds.length,
    );
  }

  Future<void> pause() async {
    if (_disposed || _paused) return;
    _paused = true;
    _operationToken++;
    _flowRunning = false;
    _recordingCountdownTimer?.cancel();
    await _recorder.cancel();
    if (!_disposed && !_state.isComplete) {
      _setState(
        _state.copyWith(
          phase: GamePhase.instruction,
          countdown: timings.recordingDuration.inSeconds,
          recordProgress: 0,
          message: 'Ready when you are.',
        ),
      );
    }
  }

  void resume() {
    if (_disposed || !_paused || _state.isComplete) return;
    _paused = false;
    start();
  }

  Future<void> cancel() async {
    _operationToken++;
    _flowRunning = false;
    _recordingCountdownTimer?.cancel();
    await _recorder.cancel();
  }

  void _setState(GameSessionState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  bool _isCurrent(int token) {
    return !_disposed && !_paused && token == _operationToken;
  }

  void _releaseFlow(int token) {
    if (token == _operationToken) _flowRunning = false;
  }

  void _startRecordingCountdown(int token) {
    _recordingCountdownTimer?.cancel();
    final startedAt = DateTime.now();
    _recordingCountdownTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) {
        if (!_isCurrent(token) || _state.phase != GamePhase.recording) {
          timer.cancel();
          return;
        }

        final elapsed = DateTime.now().difference(startedAt);
        final progress =
            elapsed.inMilliseconds / timings.recordingDuration.inMilliseconds;
        final remaining = timings.recordingDuration - elapsed;
        _setState(
          _state.copyWith(
            recordProgress: progress.clamp(0, 1).toDouble(),
            countdown: remaining.inMilliseconds <= 0
                ? 0
                : (remaining.inMilliseconds / 1000).ceil(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _operationToken++;
    _recordingCountdownTimer?.cancel();
    completionResult.dispose();
    unawaited(_recorder.dispose());
    super.dispose();
  }
}
