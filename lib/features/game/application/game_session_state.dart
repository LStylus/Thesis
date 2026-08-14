import '../../../gamescene/game_scene_state.dart';
import '../../../services/phoneme_assessment_service.dart';
import '../domain/game_level_config.dart';
import '../domain/game_target.dart';

class GameSessionState {
  final GamePhase phase;
  final String childName;
  final String levelTitle;
  final List<GameTarget> targets;
  final int targetIndex;
  final int retryCount;
  final int attemptCount;
  final int countdown;
  final double recordProgress;
  final int? lastAccuracy;
  final PhonemeAssessmentResult? lastAssessment;
  final String? message;
  final Set<String> completedTargetIds;
  final Set<String> needsPracticeTargetIds;
  final Map<String, int> targetAccuracies;

  GameSessionState({
    required this.phase,
    required this.childName,
    required this.levelTitle,
    required List<GameTarget> targets,
    required this.targetIndex,
    this.retryCount = 0,
    this.attemptCount = 0,
    this.countdown = 0,
    this.recordProgress = 0,
    this.lastAccuracy,
    this.lastAssessment,
    this.message,
    Set<String> completedTargetIds = const {},
    Set<String> needsPracticeTargetIds = const {},
    Map<String, int> targetAccuracies = const {},
  }) : targets = List.unmodifiable(targets),
       completedTargetIds = Set.unmodifiable(completedTargetIds),
       needsPracticeTargetIds = Set.unmodifiable(needsPracticeTargetIds),
       targetAccuracies = Map.unmodifiable(targetAccuracies);

  factory GameSessionState.initial({required GameLevelConfig config}) {
    return GameSessionState(
      phase: GamePhase.loading,
      childName: config.childName,
      levelTitle: config.title,
      targets: const [], // loaded asynchronously by the controller
      targetIndex: 0,
      countdown: GameSessionControllerDefaults.recordingSeconds,
    );
  }

  GameTarget get currentTarget {
    if (targets.isEmpty) {
      throw StateError('A game level must contain at least one target.');
    }
    return targets[targetIndex.clamp(0, targets.length - 1)];
  }

  bool get canRetry =>
      phase == GamePhase.invalidAudio || phase == GamePhase.error;

  bool get isComplete => phase == GamePhase.completed;

  int averageAccuracy() {
    if (targetAccuracies.isEmpty) return 0;
    final total = targetAccuracies.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    return (total / targetAccuracies.length).round().clamp(0, 100);
  }

  GameSessionState copyWith({
    GamePhase? phase,
    String? childName,
    String? levelTitle,
    List<GameTarget>? targets,
    int? targetIndex,
    int? retryCount,
    int? attemptCount,
    int? countdown,
    double? recordProgress,
    Object? lastAccuracy = _unset,
    Object? lastAssessment = _unset,
    Object? message = _unset,
    Set<String>? completedTargetIds,
    Set<String>? needsPracticeTargetIds,
    Map<String, int>? targetAccuracies,
  }) {
    return GameSessionState(
      phase: phase ?? this.phase,
      childName: childName ?? this.childName,
      levelTitle: levelTitle ?? this.levelTitle,
      targets: targets ?? this.targets,
      targetIndex: targetIndex ?? this.targetIndex,
      retryCount: retryCount ?? this.retryCount,
      attemptCount: attemptCount ?? this.attemptCount,
      countdown: countdown ?? this.countdown,
      recordProgress: recordProgress ?? this.recordProgress,
      lastAccuracy: identical(lastAccuracy, _unset)
          ? this.lastAccuracy
          : lastAccuracy as int?,
      lastAssessment: identical(lastAssessment, _unset)
          ? this.lastAssessment
          : lastAssessment as PhonemeAssessmentResult?,
      message: identical(message, _unset) ? this.message : message as String?,
      completedTargetIds: completedTargetIds ?? this.completedTargetIds,
      needsPracticeTargetIds:
          needsPracticeTargetIds ?? this.needsPracticeTargetIds,
      targetAccuracies: targetAccuracies ?? this.targetAccuracies,
    );
  }
}

class GameSessionControllerDefaults {
  static const int recordingSeconds = 3;
}

const Object _unset = Object();
