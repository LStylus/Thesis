part of 'game_session_controller.dart';

extension GameSessionSceneMapper on GameSessionController {
  GameSceneState toSceneState() {
    final hasTargets = _state.targets.isNotEmpty;
    final target = hasTargets ? _state.currentTarget : null;
    final currentNumber = hasTargets
        ? (_state.targetIndex + 1).clamp(1, _state.targets.length)
        : 0;

    return GameSceneState(
      levelKind: config.kind,
      phase: _state.phase,
      childName: config.childName,
      levelTitle: config.title,
      speechText: _state.message ?? config.kind.instruction,
      targetText: target?.promptText ?? '',
      focusText: target?.focusText ?? '',
      targetAssetPath: target?.imageAssetPath,
      progressText: hasTargets
          ? '$currentNumber / ${_state.targets.length}'
          : '',
      currentTarget: currentNumber,
      targetCount: _state.targets.length,
      micProgress: _state.recordProgress,
      countdown: _state.countdown,
      score: _state.lastAccuracy,
      completedTargetCount: _state.completedTargetIds.length,
      needsPractice:
          target != null && _state.needsPracticeTargetIds.contains(target.id),
    );
  }
}
