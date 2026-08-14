import '../../../models/learning_module_model.dart';
import '../../../models/screening_word_model.dart';
import 'game_level_kind.dart';
import 'game_target.dart';

/// Builds dynamic gameplay targets from a learning module.
///
/// The module's four levels map directly onto the game's four levels:
/// syllable → Bubble Bay, word → Coral Cargo, phrase → Reef Route,
/// sentence → Captain's Call.  Every item is its own target and is
/// assessed as-is — the phoneme service reports whichever phonemes were
/// wrong, not just a single "target sound" (all module items are in the
/// curated word list, so they are all assessable).
class LearningModuleTargets {
  static const int _maxTargetsPerLevel = 4;

  static List<GameTarget> targetsFor({
    required LearningModuleModel module,
    required GameLevelKind kind,
    required int childAge,
  }) {
    final levelName = switch (kind) {
      GameLevelKind.bubbleBay => 'syllable',
      GameLevelKind.coralCargo => 'word',
      GameLevelKind.reefRoute => 'phrase',
      GameLevelKind.captainsCall => 'sentence',
    };

    final items = module.itemsFor(levelName).take(_maxTargetsPerLevel).toList();

    return items.map((item) {
      final assessedWord = item.text.trim();
      return GameTarget(
        id: 'module_${levelName}_$assessedWord',
        promptText: _promptFor(levelName, item.text),
        focusText: item.text,
        assessmentModel: ScreeningWordModel(
          id: 'module_${levelName}_$assessedWord',
          audioId: assessedWord,
          displayWord: assessedWord,
          age: childAge,
        ),
      );
    }).toList();
  }

  static String _promptFor(String levelName, String text) {
    if (levelName == 'sentence') {
      return text.endsWith('.') ? text : '$text.';
    }
    return text.toUpperCase();
  }
}
