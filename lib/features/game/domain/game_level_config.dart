import '../../../models/speech_profile_model.dart';
import 'game_personalization_engine.dart';
import 'game_target.dart';
import 'game_template_kind.dart';

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
  List<GameTarget> buildTargets() => definition.targets;
}
