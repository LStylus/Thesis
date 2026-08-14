part of 'game_session_controller.dart';

extension GameSessionFlow on GameSessionController {
  Future<void> _prepareAndStart() async {
    if (_disposed || _paused || _flowRunning) return;

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

    // Load targets (learning module when available, CSV fallback otherwise)
    if (_state.targets.isEmpty) {
      List<GameTarget> targets;
      try {
        targets = await resolveTargets();
      } catch (error) {
        debugPrint('[game] target_load_error error=$error');
        targets = const [];
      }
      if (!_isCurrent(token)) {
        _releaseFlow(token);
        return;
      }
      _state = _state.copyWith(targets: targets);
      if (targets.isEmpty) {
        _setState(
          _state.copyWith(
            phase: GamePhase.error,
            message: 'No practice words are available for this level.',
          ),
        );
        _releaseFlow(token);
        return;
      }
    }

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
              ? 'Microphone permission is needed before this game can begin.'
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
          message: config.template.instruction,
        ),
      );
      await Future<void>.delayed(timings.levelCaptionDuration);
      if (!_isCurrent(token)) {
        _releaseFlow(token);
        return;
      }
    }

    _presentCurrentTarget(token);
  }

  void _presentCurrentTarget(int token) {
    if (!_isCurrent(token)) {
      _releaseFlow(token);
      return;
    }
    _setState(
      _state.copyWith(
        phase: GamePhase.interaction,
        message: config.template.instruction,
        lastAssessment: null,
        lastAccuracy: null,
        countdown: timings.recordingDuration.inSeconds,
        recordProgress: 0,
        micLevel: 0,
      ),
    );
    _releaseFlow(token);
  }

  Future<void> _recordCurrentTarget(int token) async {
    if (!_isCurrent(token)) {
      _releaseFlow(token);
      return;
    }
    final target = _state.currentTarget;

    _setState(
      _state.copyWith(
        phase: GamePhase.instruction,
        message: 'Get ready: ${target.promptText}',
        countdown: timings.recordingDuration.inSeconds,
        recordProgress: 0,
        micLevel: 0,
      ),
    );
    unawaited(_playPromptAudio(target));
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
        micLevel: 0,
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
          message: 'I could not hear that clearly. Let us try once more.',
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
    if (score >= config.masteryThreshold) {
      await _completeCurrentTarget(token, score, assessment);
      return;
    }

    final retryCount = _state.retryCount + 1;
    if (retryCount > _maxRetriesPerTarget) {
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
    _presentCurrentTarget(token);
  }

  Future<void> _completeCurrentTarget(
    int token,
    int score,
    PhonemeAssessmentResult assessment, {
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
            ? 'Good effort. This sound is saved for review.'
            : 'Clear speaking!',
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
        message: 'Next challenge!',
        countdown: timings.recordingDuration.inSeconds,
        recordProgress: 0,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    _presentCurrentTarget(token);
  }

  String _retryMessageForScore(int score) {
    return score < 50
        ? 'Good try. Watch the caption and make the sound slowly.'
        : 'Almost there. Keep the sound clear from start to finish.';
  }
}
