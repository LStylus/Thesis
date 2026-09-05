import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/domain/game_config.dart';
import 'package:thesis/features/game/domain/game_definition.dart';
import 'package:thesis/features/game/domain/game_stage.dart';
import 'package:thesis/features/game/domain/game_target.dart';
import 'package:thesis/models/screening_word_model.dart';

void main() {
  test('design catalog has exactly fifteen unique stable IDs', () {
    expect(GameDefinition.values, hasLength(15));
    expect(GameDefinition.values.map((game) => game.id), [
      'picture_listen',
      'sound_emphasis',
      'falling_sound_bubbles',
      'find_the_word',
      'find_the_sound',
      'sound_bucket',
      'build_and_say',
      'guided_training_path',
      'listen_pop_and_repeat',
      'forest_discovery',
      'silly_monster',
      'build_the_bridge',
      'talk_with_buddy',
      'mission_roleplay',
      'story_adventure',
    ]);
    expect(GameDefinition.values.map((game) => game.id).toSet(), hasLength(15));
  });

  test('five learning stages each describe exactly three games', () {
    expect(GameStage.values.map((stage) => stage.number), [1, 2, 3, 4, 5]);
    for (final stage in GameStage.values) {
      expect(
        GameDefinition.values.where((game) => game.stage == stage),
        hasLength(3),
      );
    }
    expect(GameDefinition.values.map((game) => game.stage), [
      for (final stage in GameStage.values) ...[stage, stage, stage],
    ]);
  });

  test('speech is required only from Guided Say onward', () {
    expect(GameStage.values.map((stage) => stage.requiresSpeech), [
      false,
      false,
      true,
      true,
      true,
    ]);
  });

  test('config preserves explicit stage choice and snapshots content', () {
    final targets = <GameTarget>[
      const GameTarget(
        id: 'key',
        promptText: 'KEY',
        focusText: 'key',
        targetSound: 'k',
        soundPosition: 'initial',
        contentUnit: 'word',
        assessmentModel: ScreeningWordModel(
          id: 'key',
          audioId: 'key',
          displayWord: 'key',
          age: 6,
        ),
      ),
    ];
    final config = GameConfig(
      definition: GameDefinition.buildAndSay,
      childProfileId: 'child-test',
      childAge: 6,
      targets: targets,
    );
    targets.clear();
    expect(config.targets.single.id, 'key');
    expect(config.stage, GameStage.guidedSay);
    expect(config.targets.single.contentUnit, 'word');
    expect(config.childAge, 6);
    expect(() => config.targets.clear(), throwsUnsupportedError);
  });
}
