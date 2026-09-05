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
      ModuleLevelModel(
        level: 'syllable',
        items: [
          PracticeItemModel(text: 'sa', targetSound: '', position: ''),
          PracticeItemModel(text: 'see', targetSound: '', position: ''),
          PracticeItemModel(text: 'so', targetSound: '', position: ''),
          PracticeItemModel(text: 'si', targetSound: '', position: ''),
        ],
      ),
      ModuleLevelModel(
        level: 'word',
        items: [
          PracticeItemModel(text: 'sea', targetSound: 's', position: 'initial'),
          PracticeItemModel(text: 'sun', targetSound: '', position: ''),
        ],
      ),
      ModuleLevelModel(
        level: 'phrase',
        items: [
          PracticeItemModel(text: 'see the sea', targetSound: '', position: ''),
        ],
      ),
      ModuleLevelModel(
        level: 'sentence',
        items: [
          PracticeItemModel(
            text: 'I see a sock.',
            targetSound: '',
            position: '',
          ),
        ],
      ),
    ],
    rationale: 'test',
    generatedBy: 'llm',
  );
}

void main() {
  group('LearningModuleTargets', () {
    test(
      'preserves the complete module in source order without repetition',
      () {
        final targets = LearningModuleTargets.targetsFor(
          module: _module(),
          childAge: 5,
        );
        expect(targets, hasLength(8));
        expect(targets.map((t) => t.focusText).toList(), [
          'sa',
          'see',
          'so',
          'si',
          'sea',
          'sun',
          'see the sea',
          'I see a sock.',
        ]);
        expect(targets.first.promptText, 'SA');
        expect(targets.first.assessmentModel.displayWord, 'sa');
        expect(targets.first.assessmentModel.age, 5);
      },
    );

    test(
      'keeps personalization metadata without assigning learning stages',
      () {
        final targets = LearningModuleTargets.targetsFor(
          module: _module(),
          childAge: 6,
        );
        expect(targets[4].targetSound, 's');
        expect(targets[4].soundPosition, 'initial');
        expect(targets[4].contentUnit, 'word');
        expect(targets[7].promptText, 'I see a sock.');
        expect(targets[6].promptText, 'SEE THE SEA');
        expect(targets[4].assessmentModel.age, 6);
        expect(targets.map((t) => t.id).toSet(), hasLength(targets.length));
        expect(() => targets.clear(), throwsUnsupportedError);
      },
    );

    test('appends a period only when the sentence lacks one', () {
      final module = LearningModuleModel(
        moduleId: 'm',
        focusSounds: const ['s'],
        focusProcesses: const [],
        outlineId: 'o',
        outlineTitle: 't',
        levels: const [
          ModuleLevelModel(
            level: 'sentence',
            items: [
              PracticeItemModel(
                text: 'I see a sock',
                targetSound: '',
                position: '',
              ),
            ],
          ),
        ],
        rationale: '',
        generatedBy: 'llm',
      );
      final targets = LearningModuleTargets.targetsFor(
        module: module,
        childAge: 5,
      );
      expect(targets.single.promptText, 'I see a sock.');
    });

    test('every item is assessed as-is (no target-sound remapping)', () {
      final targets = LearningModuleTargets.targetsFor(
        module: _module(),
        childAge: 5,
      );
      expect(targets.map((t) => t.assessmentModel.displayWord).toList(), [
        'sa',
        'see',
        'so',
        'si',
        'sea',
        'sun',
        'see the sea',
        'I see a sock.',
      ]);
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
        LearningModuleTargets.targetsFor(module: module, childAge: 5),
        isEmpty,
      );
    });
  });
}
