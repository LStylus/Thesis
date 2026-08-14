import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../gamescene/game_scene_state.dart';
import '../../../services/phoneme_assessment_service.dart';
import '../domain/game_level_config.dart';
import '../domain/game_template_kind.dart';
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
  StreamSubscription<double>? _amplitudeSubscription;
  int _operationToken = 0;
  bool _flowRunning = false;
  bool _levelCaptionShown = false;
  bool _paused = false;
  bool _disposed = false;

  GameSessionController({
    required this.config,
    required GameRecorder recorder,
    required GameAssessmentClient assessmentClient,
    this.timings = const GameSessionTimings(),
  }) : _recorder = recorder,
       _assessmentClient = assessmentClient {
    _state = GameSessionState.initial(config: config);
    _amplitudeSubscription = _recorder.amplitudeLevels.listen(
      _handleAmplitude,
      onError: (_) {},
    );
  }

  factory GameSessionController.createDefault(GameLevelConfig config) {
    return GameSessionController(
      config: config,
      recorder: AudioGameRecorder(),
      assessmentClient: Model2GameAssessmentClient(),
    );
  }

  GameSessionState get state => _state;

  int get _maxRetriesPerTarget =>
      config.difficulty == GameDifficulty.supported ? 2 : 1;

  void start() {
    if (_disposed || _flowRunning) return;
    unawaited(_prepareAndStart());
  }

  void retryCurrent() {
    if (_disposed || _flowRunning || !_state.canRetry) return;
    unawaited(_prepareAndStart());
  }

  void completeInteraction() {
    if (_disposed || _paused || _flowRunning) return;
    if (_state.phase != GamePhase.interaction) return;

    _flowRunning = true;
    final token = ++_operationToken;
    unawaited(_recordCurrentTarget(token));
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
          micLevel: 0,
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

  void _handleAmplitude(double level) {
    if (_disposed || _state.phase != GamePhase.recording) return;
    final smoothed = (_state.micLevel * .62 + level * .38).clamp(0.0, 1.0);
    _setState(_state.copyWith(micLevel: smoothed));
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
    unawaited(_amplitudeSubscription?.cancel());
    completionResult.dispose();
    unawaited(_recorder.dispose());
    super.dispose();
  }
}
