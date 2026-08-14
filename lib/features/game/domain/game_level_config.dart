import 'game_level_kind.dart';
import 'game_target.dart';
import 'game_target_catalog.dart';

/// Level structure for gameplay (4 levels per island).
///
/// Target CONTENT comes from the learning module when available, otherwise
/// from the fallback CSV catalog (`GameTargetCatalog`).
class GameLevelConfig {
  final String childProfileId;
  final String childName;
  final int childAge;
  final int levelIndex;

  const GameLevelConfig({
    required this.childProfileId,
    required this.childName,
    required this.childAge,
    required this.levelIndex,
  });

  GameLevelKind get kind => GameLevelKind.values[levelIndex.clamp(0, 3)];

  String get title => kind.title;

  /// Fallback targets for this level (CSV catalog) — used when no
  /// learning module exists.
  Future<List<GameTarget>> buildTargets() {
    return GameTargetCatalog.targetsFor(kind);
  }
}
