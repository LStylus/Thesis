/// Learning stages, separate from the backend's syllable/word/phrase units.
/// This metadata does not select a child's starting stage or unlock games.
enum GameStage {
  listen(1, 'Listen', requiresSpeech: false),
  recognize(2, 'Recognize', requiresSpeech: false),
  guidedSay(3, 'Guided Say', requiresSpeech: true),
  independentSay(4, 'Independent Say', requiresSpeech: true),
  useInContext(5, 'Use in Context', requiresSpeech: true);

  const GameStage(this.number, this.title, {required this.requiresSpeech});

  final int number;
  final String title;

  /// Future controllers must enforce this; touch cannot substitute for speech.
  final bool requiresSpeech;
}
