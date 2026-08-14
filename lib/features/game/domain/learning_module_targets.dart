import '../../../models/learning_module_model.dart';
import '../../../models/screening_word_model.dart';
import 'game_target.dart';

/// Builds dynamic gameplay targets from a learning module.
///
/// The module's items (syllables → words → phrases → sentences, in level
/// order) form the target pool for the template-based game.  Each game
/// level takes a rotating slice of the pool (offset by the level index)
/// so every item eventually gets practiced.  Every item is its own target
/// and is assessed as-is — the phoneme service reports whichever phonemes
/// were wrong, not just a single "target sound" (all module items are in
/// the curated word list, so they are all assessable).
class LearningModuleTargets {
  static List<GameTarget> targetsFor({
    required LearningModuleModel module,
    required int childAge,
    int count = 5,
    int startIndex = 0,
  }) {
    final entries = <({String level, PracticeItemModel item})>[
      for (final level in module.levels)
        for (final item in level.items) (level: level.level, item: item),
    ];
    if (entries.isEmpty) return const [];

    return List.generate(count, (index) {
      final entry = entries[(startIndex + index) % entries.length];
      final assessedWord = entry.item.text.trim();
      return GameTarget(
        id: 'module_${entry.level}_${startIndex + index}_$assessedWord',
        promptText: _promptFor(entry.level, entry.item.text),
        focusText: assessedWord,
        assessmentModel: ScreeningWordModel(
          id: 'module_${entry.level}_${startIndex + index}_$assessedWord',
          audioId: assessedWord,
          displayWord: assessedWord,
          age: childAge,
        ),
      );
    });
  }

  static String _promptFor(String levelName, String text) {
    if (levelName == 'sentence') {
      return text.endsWith('.') ? text : '$text.';
    }
    return text.toUpperCase();
  }
}
