import 'package:flutter_test/flutter_test.dart';
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
    test('takes a slice of the module pool in level order', () {
      final targets = LearningModuleTargets.targetsFor(
        module: _module(),
        childAge: 5,
        count: 4,
      );
      expect(targets, hasLength(4));
      expect(targets.map((t) => t.focusText).toList(),
          ['sa', 'see', 'so', 'si']);
      expect(targets.first.promptText, 'SA');
      expect(targets.first.assessmentModel.displayWord, 'sa');
      expect(targets.first.assessmentModel.age, 5);
    });

    test('cycles the pool from a start index', () {
      final targets = LearningModuleTargets.targetsFor(
        module: _module(),
        childAge: 6,
        count: 5,
        startIndex: 4,
      );
      expect(targets, hasLength(5));
      // pool: sa see so si | sea sun | see the sea | I see a sock.
      expect(targets.map((t) => t.focusText).toList(),
          ['sea', 'sun', 'see the sea', 'I see a sock.', 'sa']);
      expect(targets[3].promptText, 'I see a sock.');
      expect(targets[2].promptText, 'SEE THE SEA');
      expect(targets[4].assessmentModel.age, 6);
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
        childAge: 5,
        count: 1,
      );
      expect(targets.single.promptText, 'I see a sock.');
    });

    test('every item is assessed as-is (no target-sound remapping)', () {
      final targets = LearningModuleTargets.targetsFor(
        module: _module(),
        childAge: 5,
        count: 8,
      );
      expect(
        targets.map((t) => t.assessmentModel.displayWord).toList(),
        [
          'sa', 'see', 'so', 'si', 'sea', 'sun', 'see the sea',
          'I see a sock.',
        ],
      );
    });

    test('returns empty for a module with no items', () {
      final module = LearningModuleModel(
        moduleId: 'm',
        focusSounds: const [],
        focusProcesses: const [],
        outlineId: 'o',
        outlineTitle: 't',
        levels: const [],
        rationale: '',
        generatedBy: 'llm',
      );
      expect(
        LearningModuleTargets.targetsFor(
          module: module,
          childAge: 5,
          count: 5,
        ),
        isEmpty,
      );
    });
  });
}
