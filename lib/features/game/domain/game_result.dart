class GameResult {
  final int levelIndex;
  final bool correct;
  final int accuracy;
  final int attemptedTargetCount;
  final int needsPracticeCount;

  const GameResult({
    required this.levelIndex,
    required this.correct,
    required this.accuracy,
    this.attemptedTargetCount = 0,
    this.needsPracticeCount = 0,
  });
}
