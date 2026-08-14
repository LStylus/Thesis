import '../../../models/screening_word_model.dart';
import '../../../models/speech_profile_model.dart';
import 'game_target.dart';
import 'game_template_kind.dart';

class GameLevelDefinition {
  final GameTemplateKind template;
  final String sceneTitle;
  final String targetPattern;
  final List<String> targetPhonemes;
  final String wordPosition;
  final GameDifficulty difficulty;
  final int repetitions;
  final GameHintLevel hintLevel;
  final double masteryThreshold;
  final List<GameTarget> targets;

  const GameLevelDefinition({
    required this.template,
    required this.sceneTitle,
    required this.targetPattern,
    required this.targetPhonemes,
    required this.wordPosition,
    required this.difficulty,
    required this.repetitions,
    required this.hintLevel,
    required this.masteryThreshold,
    required this.targets,
  });
}

class GamePersonalizationEngine {
  const GamePersonalizationEngine._();

  static GameLevelDefinition build({
    required int childAge,
    required int levelIndex,
    SpeechProfileModel? profile,
  }) {
    final difficulty = _difficultyFor(profile?.averageAccuracy);
    final route = _routeFor(profile?.primaryTarget ?? '');
    final normalizedIndex = levelIndex < 0 ? 0 : levelIndex;
    final template = route[normalizedIndex % route.length];
    final repetitions = switch (difficulty) {
      GameDifficulty.supported => 5,
      GameDifficulty.guided => 4,
      GameDifficulty.independent => 3,
    };
    final approvedWords = _approvedWords(profile, childAge);
    final targets = _buildTargets(
      words: approvedWords,
      childAge: childAge,
      count: repetitions,
    );

    return GameLevelDefinition(
      template: template,
      sceneTitle: _sceneTitle(template),
      targetPattern: profile?.primaryTarget.trim().isNotEmpty == true
          ? profile!.primaryTarget
          : 'age-appropriate speech sounds',
      targetPhonemes: profile?.targetPhonemes ?? const [],
      wordPosition: profile?.wordPosition.trim().isNotEmpty == true
          ? profile!.wordPosition
          : 'mixed',
      difficulty: difficulty,
      repetitions: repetitions,
      hintLevel: switch (difficulty) {
        GameDifficulty.supported => GameHintLevel.full,
        GameDifficulty.guided => GameHintLevel.visual,
        GameDifficulty.independent => GameHintLevel.minimal,
      },
      masteryThreshold: difficulty == GameDifficulty.independent ? 85 : 80,
      targets: targets,
    );
  }

  static List<GameTemplateKind> _routeFor(String primaryTarget) {
    final target = primaryTarget.toLowerCase();
    if (target.contains('cluster')) {
      return const [
        GameTemplateKind.soundBuilder,
        GameTemplateKind.sequenceJumper,
        GameTemplateKind.minimalPairMatch,
        GameTemplateKind.voicePoweredJourney,
        GameTemplateKind.tapAndPop,
        GameTemplateKind.echoCave,
        GameTemplateKind.bucketSort,
        GameTemplateKind.soundMeterChallenge,
      ];
    }
    if (target.contains('front') || target.contains('back')) {
      return const [
        GameTemplateKind.minimalPairMatch,
        GameTemplateKind.bucketSort,
        GameTemplateKind.voicePoweredJourney,
        GameTemplateKind.echoCave,
        GameTemplateKind.soundBuilder,
        GameTemplateKind.tapAndPop,
        GameTemplateKind.sequenceJumper,
        GameTemplateKind.soundMeterChallenge,
      ];
    }
    if (target.contains('stop')) {
      return const [
        GameTemplateKind.echoCave,
        GameTemplateKind.soundMeterChallenge,
        GameTemplateKind.minimalPairMatch,
        GameTemplateKind.tapAndPop,
        GameTemplateKind.soundBuilder,
        GameTemplateKind.bucketSort,
        GameTemplateKind.sequenceJumper,
        GameTemplateKind.voicePoweredJourney,
      ];
    }
    if (target.contains('final') || target.contains('delet')) {
      return const [
        GameTemplateKind.soundBuilder,
        GameTemplateKind.bucketSort,
        GameTemplateKind.tapAndPop,
        GameTemplateKind.sequenceJumper,
        GameTemplateKind.echoCave,
        GameTemplateKind.minimalPairMatch,
        GameTemplateKind.voicePoweredJourney,
        GameTemplateKind.soundMeterChallenge,
      ];
    }
    return GameTemplateKind.values;
  }

  static GameDifficulty _difficultyFor(double? accuracy) {
    if (accuracy == null || accuracy < 60) return GameDifficulty.supported;
    if (accuracy < 82) return GameDifficulty.guided;
    return GameDifficulty.independent;
  }

  static List<String> _approvedWords(
    SpeechProfileModel? profile,
    int childAge,
  ) {
    final personalized = profile?.approvedWords
        .map((word) => word.trim().toUpperCase())
        .where((word) => word.isNotEmpty)
        .toSet()
        .toList();
    if (personalized != null && personalized.isNotEmpty) return personalized;

    return _wordsForAge(
      childAge,
    ).map((word) => word.displayWord).toSet().toList(growable: false);
  }

  static List<GameTarget> _buildTargets({
    required List<String> words,
    required int childAge,
    required int count,
  }) {
    final pool = words.isEmpty ? const ['SAY'] : words;
    final agePool = _wordsForAge(
      childAge,
    ).map((word) => word.displayWord.toUpperCase()).toList(growable: false);
    return List.generate(count, (index) {
      final display = pool[index % pool.length].toUpperCase();
      final distractor = [
        ...pool.map((word) => word.toUpperCase()),
        ...agePool,
      ].firstWhere((word) => word != display, orElse: () => 'ANOTHER');
      final correctIndex = index.isEven ? 0 : 1;
      final model = _assessmentWord(display, childAge, index);
      return GameTarget(
        id: '${model.id}_game_$index',
        promptText: display,
        focusText: display,
        imageAssetPath: _wordAsset(display),
        assessmentModel: model,
        pieces: _piecesFor(display),
        options: correctIndex == 0
            ? [display, distractor]
            : [distractor, display],
        correctOptionIndex: correctIndex,
      );
    });
  }

  static ScreeningWordModel _assessmentWord(
    String display,
    int age,
    int index,
  ) {
    final candidates = _wordsForAge(age);
    for (final word in candidates) {
      if (word.displayWord.toUpperCase() == display) return word;
    }
    final id = display.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return ScreeningWordModel(
      id: '${id}_game_$index',
      audioId: id,
      displayWord: display,
      age: age.clamp(4, 8).toInt(),
    );
  }

  static List<ScreeningWordModel> _wordsForAge(int age) {
    if (age <= 4) return ScreeningWordModel.age4Words;
    if (age == 5) return ScreeningWordModel.age5Words;
    if (age <= 7) return ScreeningWordModel.age6To7Words;
    return ScreeningWordModel.age8Words;
  }

  static List<String> _piecesFor(String word) {
    final letters = word.replaceAll(' ', '').split('');
    if (letters.length <= 5) return letters;
    final midpoint = (letters.length / 2).ceil();
    return [letters.take(midpoint).join(), letters.skip(midpoint).join()];
  }

  static String? _wordAsset(String word) {
    const assets = {
      'PIG': 'pig.svg',
      'BALL': 'ball.svg',
      'TEN': '10.svg',
      'DOG': 'dog.svg',
      'KEY': 'key.svg',
      'GOAT': 'goat.svg',
    };
    final name = assets[word];
    return name == null ? null : 'assets/game/words/$name';
  }

  static String _sceneTitle(GameTemplateKind template) => switch (template) {
    GameTemplateKind.soundBuilder => 'Name and Letter Station',
    GameTemplateKind.bucketSort => 'Classroom Bag Collector',
    GameTemplateKind.tapAndPop => 'Sound Meadow Clean-Up',
    GameTemplateKind.minimalPairMatch => 'Mirror Word Match',
    GameTemplateKind.echoCave => 'Story Echo Hollow',
    GameTemplateKind.sequenceJumper => 'Stepping Word Trail',
    GameTemplateKind.voicePoweredJourney => 'Voice Bridge Adventure',
    GameTemplateKind.soundMeterChallenge => 'Clear Voice Meter',
  };
}
