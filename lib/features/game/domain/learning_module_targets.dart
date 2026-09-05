import '../../../models/learning_module_model.dart';
import '../../../models/screening_word_model.dart';
import 'game_target.dart';

/// Builds dynamic gameplay targets from a learning module.
///
/// Preserves every item and its targeting metadata in source order.
/// This adapter does not choose stages, repetitions, or gameplay difficulty.
class LearningModuleTargets {
  static List<GameTarget> targetsFor({
    required LearningModuleModel module,
    required int childAge,
  }) {
    final entries = <({String level, PracticeItemModel item})>[
      for (final level in module.levels)
        for (final item in level.items) (level: level.level, item: item),
    ];
    if (entries.isEmpty) return const [];

    return List<GameTarget>.unmodifiable(
      List.generate(entries.length, (index) {
        final entry = entries[index];
        final assessedWord = entry.item.text.trim();
        return GameTarget(
          id: 'module_${module.moduleId}_${entry.level}_${index}_$assessedWord',
          promptText: _promptFor(entry.level, entry.item.text),
          focusText: assessedWord,
          targetSound: entry.item.targetSound,
          soundPosition: entry.item.position,
          contentUnit: entry.level,
          assessmentModel: ScreeningWordModel(
            id: 'module_${module.moduleId}_${entry.level}_${index}_$assessedWord',
            audioId: assessedWord,
            displayWord: assessedWord,
            age: childAge,
          ),
        );
      }),
    );
  }

  static String _promptFor(String levelName, String text) {
    if (levelName == 'sentence') {
      return text.endsWith('.') ? text : '$text.';
    }
    return text.toUpperCase();
  }
}
