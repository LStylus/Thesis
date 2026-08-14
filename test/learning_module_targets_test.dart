import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/domain/game_level_kind.dart';
import 'package:thesis/features/game/domain/learning_module_targets.dart';
import 'package:thesis/models/learning_module_model.dart';

LearningModuleModel _module() {
  return LearningModuleModel(
    moduleId: 'mod-test',
    focusSounds: const ['s'],
    focusProcesses: const ['Stopping'],
    outlineId: 'stopping-s',
    outlineTitle: 'Stopping: /s/ practice',
    levels: const [
      ModuleLevelModel(level: 'syllable', items: [
        PracticeItemModel(text: 'sa', targetSound: '', position: ''),
        PracticeItemModel(text: 'see', targetSound: '', position: ''),
        PracticeItemModel(text: 'so', targetSound: '', position: ''),
        PracticeItemModel(text: 'si', targetSound: '', position: ''),
        PracticeItemModel(text: 'ke', targetSound: '', position: ''),
      ]),
      ModuleLevelModel(level: 'word', items: [
        PracticeItemModel(text: 'sea', targetSound: '', position: ''),
        PracticeItemModel(text: 'sun', targetSound: '', position: ''),
      ]),
      ModuleLevelModel(level: 'phrase', items: [
        PracticeItemModel(text: 'see the sea', targetSound: '', position: ''),
      ]),
      ModuleLevelModel(level: 'sentence', items: [
        PracticeItemModel(text: 'I see a sock.', targetSound: '', position: ''),
      ]),
    ],
    rationale: 'test',
    generatedBy: 'llm',
  );
}

void main() {
  group('LearningModuleTargets', () {
    test('maps module syllable items to Bubble Bay targets', () {
      final targets = LearningModuleTargets.targetsFor(
        module: _module(),
        kind: GameLevelKind.bubbleBay,
        childAge: 5,
      );
      expect(targets, hasLength(4)); // capped at 4 (ke dropped)
      expect(targets.first.promptText, 'SA');
      expect(targets.first.focusText, 'sa');
      expect(targets.first.assessmentModel.displayWord, 'sa');
      expect(targets.first.assessmentModel.age, 5);
    });

    test('maps module word items to Coral Cargo targets', () {
      final targets = LearningModuleTargets.targetsFor(
        module: _module(),
        kind: GameLevelKind.coralCargo,
        childAge: 6,
      );
      expect(targets, hasLength(2));
      expect(targets.first.promptText, 'SEA');
      expect(targets.first.assessmentModel.displayWord, 'sea');
      expect(targets.first.assessmentModel.age, 6);
    });

    test('maps module phrase items to Reef Route targets', () {
      final targets = LearningModuleTargets.targetsFor(
        module: _module(),
        kind: GameLevelKind.reefRoute,
        childAge: 5,
      );
      expect(targets, hasLength(1));
      expect(targets.first.promptText, 'SEE THE SEA');
      expect(targets.first.assessmentModel.displayWord, 'see the sea');
    });

    test('maps module sentence items to Captain\'s Call targets', () {
      final targets = LearningModuleTargets.targetsFor(
        module: _module(),
        kind: GameLevelKind.captainsCall,
        childAge: 5,
      );
      expect(targets, hasLength(1));
      // sentence already ends with '.' — no double period
      expect(targets.first.promptText, 'I see a sock.');
      expect(targets.first.assessmentModel.displayWord, 'I see a sock.');
    });

    test('appends a period only when the sentence lacks one', () {
      final module = LearningModuleModel(
        moduleId: 'm',
        focusSounds: const ['s'],
        focusProcesses: const [],
        outlineId: 'o',
        outlineTitle: 't',
        levels: const [
          ModuleLevelModel(level: 'sentence', items: [
            PracticeItemModel(text: 'I see a sock', targetSound: '', position: ''),
          ]),
        ],
        rationale: '',
        generatedBy: 'llm',
      );
      final targets = LearningModuleTargets.targetsFor(
        module: module,
        kind: GameLevelKind.captainsCall,
        childAge: 5,
      );
      expect(targets.single.promptText, 'I see a sock.');
    });

    test('every item is assessed as-is (no target-sound remapping)', () {
      final targets = LearningModuleTargets.targetsFor(
        module: _module(),
        kind: GameLevelKind.coralCargo,
        childAge: 5,
      );
      expect(targets.map((t) => t.assessmentModel.displayWord).toList(),
          ['sea', 'sun']);
    });
  });
}
