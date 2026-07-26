part of 'game_session_controller.dart';

extension GameSessionFlow on GameSessionController {
  Future<void> _prepareAndStart() async {
    if (_disposed || _paused || _flowRunning || _state.targets.isEmpty) return;

    _flowRunning = true;
    final token = ++_operationToken;
    _setState(
      _state.copyWith(
        phase: GamePhase.loading,
        message: null,
        lastAssessment: null,
        lastAccuracy: null,
      ),
    );

    final readiness = await _recorder.prepare();
    if (!_isCurrent(token)) {
      _releaseFlow(token);
      return;
    }
    if (readiness != GameRecorderReadiness.ready) {
      _setState(
        _state.copyWith(
          phase: GamePhase.error,
          message: readiness == GameRecorderReadiness.permissionDenied
              ? 'Microphone permission is needed before this voyage can begin.'
              : 'The microphone is not ready. Please try again.',
        ),
      );
      _releaseFlow(token);
      return;
    }

    if (!_levelCaptionShown) {
      _levelCaptionShown = true;
      _setState(
        _state.copyWith(
          phase: GamePhase.instruction,
          message: config.kind.instruction,
        ),
      );
      await Future<void>.delayed(timings.levelCaptionDuration);
      if (!_isCurrent(token)) {
        _releaseFlow(token);
        return;
      }
    }

    await _runCurrentTarget(token);
  }

  Future<void> _runCurrentTarget(int token) async {
    if (!_isCurrent(token)) {
      _releaseFlow(token);
      return;
    }
    final target = _state.currentTarget;

    _setState(
      _state.copyWith(
        phase: GamePhase.instruction,
        message: 'Get ready: ${target.promptText}',
        lastAssessment: null,
        lastAccuracy: null,
        countdown: timings.recordingDuration.inSeconds,
        recordProgress: 0,
      ),
    );
    await Future<void>.delayed(timings.targetCaptionDuration);
    if (!_isCurrent(token)) {
      _releaseFlow(token);
      return;
    }

    _setState(
      _state.copyWith(
        phase: GamePhase.recording,
        message: 'Say: ${target.promptText}',
        attemptCount: _state.attemptCount + 1,
        countdown: timings.recordingDuration.inSeconds,
        recordProgress: 0,
      ),
    );
    _startRecordingCountdown(token);

    final recordingPath = await _recorder.recordTimed(
      fileNamePrefix: '${config.childProfileId}_${target.id}',
      duration: timings.recordingDuration,
    );
    _recordingCountdownTimer?.cancel();
    if (!_isCurrent(token)) {
      _releaseFlow(token);
      return;
    }

    if (recordingPath == null) {
      _setState(
        _state.copyWith(
          phase: GamePhase.invalidAudio,
          message: 'The waves were noisy. Let\'s try again.',
          countdown: timings.recordingDuration.inSeconds,
          recordProgress: 0,
        ),
      );
      _releaseFlow(token);
      return;
    }

    _setState(
      _state.copyWith(
        phase: GamePhase.processing,
        message: 'Checking ${target.promptText}...',
        countdown: 0,
        recordProgress: 1,
      ),
    );

    final assessment = await _assessmentClient.assess(
      word: target.assessmentModel,
      recordingPath: recordingPath,
    );
    if (!_isCurrent(token)) {
      _releaseFlow(token);
      return;
    }

    if (!assessment.isSuccess) {
      debugPrint(
        '[game-session] assessment_failed target=${target.id} '
        'error=${assessment.error}',
      );
      _setState(
        _state.copyWith(
          phase: GamePhase.error,
          lastAssessment: assessment,
          message: 'We could not check that recording. Please try again.',
        ),
      );
      _releaseFlow(token);
      return;
    }

    final score = assessment.overallScore!.round().clamp(0, 100);
    if (score >= GameSessionController.passingScore) {
      await _completeCurrentTarget(token, score, assessment);
      return;
    }

    final retryCount = _state.retryCount + 1;
    if (retryCount > GameSessionController.maxRetriesPerTarget) {
      final needsPractice = {..._state.needsPracticeTargetIds, target.id};
      _setState(_state.copyWith(needsPracticeTargetIds: needsPractice));
      await _completeCurrentTarget(token, score, assessment, assisted: true);
      return;
    }

    _setState(
      _state.copyWith(
        phase: GamePhase.retry,
        retryCount: retryCount,
        lastAccuracy: score,
        lastAssessment: assessment,
        message: _retryMessageForScore(score),
        recordProgress: 0,
      ),
    );
    await Future<void>.delayed(timings.feedbackHold);
    if (!_isCurrent(token)) {
      _releaseFlow(token);
      return;
    }
    await _runCurrentTarget(token);
  }

  Future<void> _completeCurrentTarget(
    int token,
    int score,
    Model2AssessmentResult assessment, {
    bool assisted = false,
  }) async {
    final target = _state.currentTarget;
    final completed = {..._state.completedTargetIds, target.id};
    final accuracies = {..._state.targetAccuracies}..[target.id] = score;

    _setState(
      _state.copyWith(
        phase: GamePhase.correct,
        completedTargetIds: completed,
        targetAccuracies: accuracies,
        lastAccuracy: score,
        lastAssessment: assessment,
        message: assisted
            ? 'Nice effort. We will practice this one again later.'
            : 'Great speaking!',
      ),
    );
    await Future<void>.delayed(timings.successHold);
    if (!_isCurrent(token)) {
      _releaseFlow(token);
      return;
    }

    final nextIndex = _state.targetIndex + 1;
    if (nextIndex >= _state.targets.length) {
      _setState(
        _state.copyWith(
          phase: GamePhase.completed,
          message: '${config.title} complete!',
          recordProgress: 0,
        ),
      );
      _releaseFlow(token);
      return;
    }

    _setState(
      _state.copyWith(
        phase: GamePhase.transitioning,
        targetIndex: nextIndex,
        retryCount: 0,
        lastAccuracy: null,
        lastAssessment: null,
        message: 'Next stop!',
        countdown: timings.recordingDuration.inSeconds,
        recordProgress: 0,
      ),
    );
    await _runCurrentTarget(token);
  }

  String _retryMessageForScore(int score) {
    return score < 50
        ? 'Good try. Read the caption and say it again.'
        : 'Almost there. Say the caption again.';
  }
}
