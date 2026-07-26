import 'package:cloud_firestore/cloud_firestore.dart';

class LearningReportLevelScore {
  final int activityIndex;
  final int levelIndex;
  final int accuracy;
  final DateTime? completedAt;

  const LearningReportLevelScore({
    required this.activityIndex,
    required this.levelIndex,
    required this.accuracy,
    this.completedAt,
  });

  String get storageKey =>
      keyFor(activityIndex: activityIndex, levelIndex: levelIndex);

  static String keyFor({required int activityIndex, required int levelIndex}) {
    return 'activity_${activityIndex + 1}_level_${levelIndex + 1}';
  }

  factory LearningReportLevelScore.fromMap(Map<String, dynamic> map) {
    return LearningReportLevelScore(
      activityIndex: _intValue(map['activityIndex']),
      levelIndex: _intValue(map['levelIndex']),
      accuracy: _intValue(map['accuracy']).clamp(0, 100).toInt(),
      completedAt: _dateValue(map['completedAt']),
    );
  }

  Map<String, dynamic> toMap({Object? completedAtValue}) {
    return {
      'activityIndex': activityIndex,
      'levelIndex': levelIndex,
      'accuracy': accuracy.clamp(0, 100).toInt(),
      'completedAt': completedAtValue ?? completedAt,
    };
  }

  static int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _dateValue(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

class LearningReportData {
  final List<LearningReportLevelScore> levelScores;

  const LearningReportData({this.levelScores = const []});

  static const empty = LearningReportData();

  int get completedLevelCount => levelScores.length;

  int get learnedWordCount => completedLevelCount * 2;

  int get practiceMinutes =>
      completedLevelCount == 0 ? 0 : completedLevelCount * 5;

  int? get averageAccuracy {
    if (levelScores.isEmpty) return null;
    final total = levelScores.fold<int>(
      0,
      (runningTotal, score) => runningTotal + score.accuracy,
    );
    return (total / levelScores.length).round().clamp(0, 100).toInt();
  }

  Set<int> completedLevelsForActivity(int activityIndex) {
    return levelScores
        .where((score) => score.activityIndex == activityIndex)
        .map((score) => score.levelIndex)
        .toSet();
  }

  LearningReportData merge(LearningReportData other) {
    final byKey = <String, LearningReportLevelScore>{
      for (final score in levelScores) score.storageKey: score,
      for (final score in other.levelScores) score.storageKey: score,
    };

    return LearningReportData(levelScores: _sortedScores(byKey.values));
  }

  factory LearningReportData.fromChildMap(Map<String, dynamic>? map) {
    final rawReport = map?['learningReport'];
    if (rawReport is! Map) return LearningReportData.empty;

    final rawScores = rawReport['levelScores'];
    if (rawScores is! Map) return LearningReportData.empty;

    final scores = rawScores.values
        .whereType<Map>()
        .map(
          (score) => LearningReportLevelScore.fromMap(
            Map<String, dynamic>.from(score),
          ),
        )
        .toList();

    return LearningReportData(levelScores: _sortedScores(scores));
  }

  static List<LearningReportLevelScore> _sortedScores(
    Iterable<LearningReportLevelScore> scores,
  ) {
    final sorted = scores.toList()
      ..sort((left, right) {
        final activityComparison = left.activityIndex.compareTo(
          right.activityIndex,
        );
        if (activityComparison != 0) return activityComparison;
        return left.levelIndex.compareTo(right.levelIndex);
      });
    return sorted;
  }
}
