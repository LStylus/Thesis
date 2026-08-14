import '../features/game/domain/game_template_kind.dart';

enum GamePhase {
  loading,
  instruction,
  interaction,
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
  final GameTemplateKind template;
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
  final double micLevel;
  final int countdown;
  final int? score;
  final bool needsPractice;
  final List<String> targetPieces;
  final List<String> targetOptions;
  final int correctOptionIndex;
  final int interactionRevision;
  final GameDifficulty difficulty;
  final GameHintLevel hintLevel;

  const GameSceneState({
    required this.template,
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
    this.micLevel = 0,
    this.countdown = 0,
    this.score,
    this.needsPractice = false,
    this.targetPieces = const [],
    this.targetOptions = const [],
    this.correctOptionIndex = 0,
    this.interactionRevision = 0,
    this.difficulty = GameDifficulty.guided,
    this.hintLevel = GameHintLevel.visual,
  });

  factory GameSceneState.initial({
    String childName = '',
    GameTemplateKind template = GameTemplateKind.soundBuilder,
  }) {
    return GameSceneState(
      template: template,
      phase: GamePhase.loading,
      childName: childName,
      levelTitle: template.title,
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
  bool get isAwaitingInteraction => phase == GamePhase.interaction;
  bool get isProcessing => phase == GamePhase.processing;
  bool get isCorrect => phase == GamePhase.correct;
  bool get isRetry =>
      phase == GamePhase.retry || phase == GamePhase.invalidAudio;
}
