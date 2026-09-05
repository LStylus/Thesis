import 'game_definition.dart';
import 'game_stage.dart';
import 'game_target.dart';

/// Immutable handoff of an explicitly chosen design and target content.
/// No default stage, content selection, scoring threshold, or level logic.
class GameConfig {
  GameConfig({
    required this.definition,
    required this.childProfileId,
    required this.childAge,
    required List<GameTarget> targets,
  }) : targets = List.unmodifiable(targets);

  final GameDefinition definition;
  final String childProfileId;
  final int childAge;
  final List<GameTarget> targets;

  GameStage get stage => definition.stage;
}
