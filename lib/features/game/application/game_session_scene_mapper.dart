part of 'game_session_controller.dart';

extension GameSessionSceneMapper on GameSessionController {
  GameSceneState toSceneState() {
    final hasTargets = _state.targets.isNotEmpty;
    final target = hasTargets ? _state.currentTarget : null;
    final currentNumber = hasTargets
        ? (_state.targetIndex + 1).clamp(1, _state.targets.length)
        : 0;

    return GameSceneState(
      template: config.template,
      phase: _state.phase,
      childName: config.childName,
      levelTitle: config.title,
      speechText: _state.message ?? config.template.instruction,
      targetText: target?.promptText ?? '',
      focusText: target?.focusText ?? '',
      targetAssetPath: target?.imageAssetPath,
      progressText: hasTargets
          ? '$currentNumber / ${_state.targets.length}'
          : '',
      currentTarget: currentNumber,
      targetCount: _state.targets.length,
      micProgress: _state.recordProgress,
      micLevel: _state.micLevel,
      countdown: _state.countdown,
      score: _state.lastAccuracy,
      completedTargetCount: _state.completedTargetIds.length,
      needsPractice:
          target != null && _state.needsPracticeTargetIds.contains(target.id),
      targetPieces: target?.pieces ?? const [],
      targetOptions: target?.options ?? const [],
      correctOptionIndex: target?.correctOptionIndex ?? 0,
      interactionRevision: _state.attemptCount,
      difficulty: config.difficulty,
      hintLevel: config.hintLevel,
    );
  }
}
