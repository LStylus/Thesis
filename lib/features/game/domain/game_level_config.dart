import '../../../models/speech_profile_model.dart';
import 'game_personalization_engine.dart';
import 'game_target.dart';
import 'game_target_catalog.dart';
import 'game_template_kind.dart';

/// Level structure for gameplay, driven by the personalization engine.
///
/// Target CONTENT resolution is layered: the controller tries the
/// persisted/refetched learning module first; this class falls back to
/// the CSV catalog (a rotating slice keyed by level index) and finally
/// to the engine's profile/static targets.
class GameLevelConfig {
  final String childProfileId;
  final String childName;
  final int childAge;
  final int levelIndex;
  final SpeechProfileModel? speechProfile;
  final GameLevelDefinition definition;

  GameLevelConfig({
    required this.childProfileId,
    required this.childName,
    required this.childAge,
    required this.levelIndex,
    this.speechProfile,
  }) : definition = GamePersonalizationEngine.build(
         childAge: childAge,
         levelIndex: levelIndex,
         profile: speechProfile,
       );

  GameTemplateKind get template => definition.template;
  String get title => definition.sceneTitle;
  String get targetPattern => definition.targetPattern;
  List<String> get targetPhonemes => definition.targetPhonemes;
  String get wordPosition => definition.wordPosition;
  GameDifficulty get difficulty => definition.difficulty;
  int get repetitions => definition.repetitions;
  GameHintLevel get hintLevel => definition.hintLevel;
  double get masteryThreshold => definition.masteryThreshold;

  /// CSV-catalog fallback: a rotating slice of the catalog keyed by the
  /// level index; then the engine's own targets as the final fallback.
  Future<List<GameTarget>> buildTargets() async {
    final catalog = await GameTargetCatalog.targets();
    if (catalog.isNotEmpty) {
      final start = (levelIndex * repetitions) % catalog.length;
      return List.generate(
        repetitions,
        (index) => catalog[(start + index) % catalog.length],
      );
    }
    return definition.targets;
  }
}
