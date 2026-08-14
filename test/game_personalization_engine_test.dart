import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/domain/game_level_config.dart';
import 'package:thesis/features/game/domain/game_template_kind.dart';
import 'package:thesis/models/speech_profile_model.dart';

void main() {
  test('the default route exposes all eight reusable templates', () {
    final templates = {
      for (var index = 0; index < 8; index++)
        GameLevelConfig(
          childProfileId: 'child-1',
          childName: 'Kai',
          childAge: 6,
          levelIndex: index,
        ).template,
    };

    expect(templates, GameTemplateKind.values.toSet());
  });

  test('screening accuracy scales repetitions and hint support', () {
    final supported = GameLevelConfig(
      childProfileId: 'child-1',
      childName: 'Kai',
      childAge: 5,
      levelIndex: 0,
      speechProfile: _profile(averageAccuracy: 42),
    );
    final independent = GameLevelConfig(
      childProfileId: 'child-1',
      childName: 'Kai',
      childAge: 5,
      levelIndex: 0,
      speechProfile: _profile(averageAccuracy: 91),
    );

    expect(supported.difficulty, GameDifficulty.supported);
    expect(supported.hintLevel, GameHintLevel.full);
    expect(supported.buildTargets(), hasLength(5));
    expect(independent.difficulty, GameDifficulty.independent);
    expect(independent.hintLevel, GameHintLevel.minimal);
    expect(independent.buildTargets(), hasLength(3));
  });

  test('cluster evidence receives a build-and-sequence route', () {
    final config = GameLevelConfig(
      childProfileId: 'child-1',
      childName: 'Kai',
      childAge: 7,
      levelIndex: 0,
      speechProfile: _profile(
        averageAccuracy: 70,
        primaryTarget: 'cluster reduction',
      ),
    );

    expect(config.template, GameTemplateKind.soundBuilder);
    expect(config.targetPattern, 'cluster reduction');
    expect(
      config.buildTargets().map((target) => target.promptText),
      everyElement(isIn(const ['STAR', 'TRUCK', 'GLOVE'])),
    );
  });
}

SpeechProfileModel _profile({
  required double averageAccuracy,
  String primaryTarget = 'final consonant deletion',
}) {
  return SpeechProfileModel(
    primaryTarget: primaryTarget,
    secondaryTarget: '',
    reviewTargets: const [],
    targetPhonemes: const ['/s/'],
    wordPosition: 'final',
    approvedWords: const ['STAR', 'TRUCK', 'GLOVE'],
    averageAccuracy: averageAccuracy,
    validAttempts: 12,
    evidenceCounts: const {'cluster reduction': 3},
  );
}
