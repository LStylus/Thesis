import '../features/game/domain/game_level_kind.dart';

enum GamePhase {
  loading,
  instruction,
  recording,
  processing,
  correct,
  retry,
  invalidAudio,
  transitioning,
  completed,
  error,
}

class GameSceneState {
  final GameLevelKind levelKind;
  final GamePhase phase;
  final String childName;
  final String levelTitle;
  final String speechText;
  final String targetText;
  final String focusText;
  final String? targetAssetPath;
  final String progressText;
  final int currentTarget;
  final int targetCount;
  final int completedTargetCount;
  final double micProgress;
  final int countdown;
  final int? score;
  final bool needsPractice;

  const GameSceneState({
    required this.levelKind,
    required this.phase,
    required this.childName,
    required this.levelTitle,
    required this.speechText,
    required this.targetText,
    required this.focusText,
    required this.progressText,
    required this.currentTarget,
    required this.targetCount,
    required this.completedTargetCount,
    this.targetAssetPath,
    this.micProgress = 0,
    this.countdown = 0,
    this.score,
    this.needsPractice = false,
  });

  factory GameSceneState.initial({
    String childName = '',
    GameLevelKind levelKind = GameLevelKind.bubbleBay,
  }) {
    return GameSceneState(
      levelKind: levelKind,
      phase: GamePhase.loading,
      childName: childName,
      levelTitle: levelKind.title,
      speechText: childName.trim().isEmpty
          ? 'Preparing your voyage...'
          : 'Preparing your voyage, $childName...',
      targetText: '',
      focusText: '',
      progressText: '',
      currentTarget: 0,
      targetCount: 0,
      completedTargetCount: 0,
    );
  }

  bool get isRecording => phase == GamePhase.recording;
  bool get isProcessing => phase == GamePhase.processing;
  bool get isCorrect => phase == GamePhase.correct;
  bool get isRetry =>
      phase == GamePhase.retry || phase == GamePhase.invalidAudio;
}
