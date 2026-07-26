import '../../../models/screening_word_model.dart';
import 'game_level_kind.dart';
import 'game_target.dart';

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

  List<GameTarget> buildTargets() {
    switch (kind) {
      case GameLevelKind.bubbleBay:
        return _bubbleBayTargets;
      case GameLevelKind.coralCargo:
        return _coralCargoTargets;
      case GameLevelKind.reefRoute:
        return _reefRouteTargets;
      case GameLevelKind.captainsCall:
        return _captainsCallTargets;
    }
  }
}

final ScreeningWordModel _pig = ScreeningWordModel.age4Words[0];
final ScreeningWordModel _ball = ScreeningWordModel.age4Words[1];
final ScreeningWordModel _ten = ScreeningWordModel.age4Words[6];
final ScreeningWordModel _dog = ScreeningWordModel.age4Words[7];
final ScreeningWordModel _key = ScreeningWordModel.age4Words[12];
final ScreeningWordModel _goat = ScreeningWordModel.age4Words[13];

final List<GameTarget> _bubbleBayTargets = [
  _derivedTarget(_pig, 'pa', 'PA', 'pig.svg', assessFullPrompt: true),
  _derivedTarget(_ball, 'ba', 'BA', 'ball.svg', assessFullPrompt: true),
  _derivedTarget(_ten, 'ta', 'TA', '10.svg', assessFullPrompt: true),
  _derivedTarget(_key, 'ka', 'KA', 'key.svg', assessFullPrompt: true),
];

final List<GameTarget> _coralCargoTargets = [
  _wordTarget(_pig, 'pig.svg'),
  _wordTarget(_ball, 'ball.svg'),
  _wordTarget(_dog, 'dog.svg'),
  _wordTarget(_key, 'key.svg'),
];

final List<GameTarget> _reefRouteTargets = [
  _derivedTarget(_pig, 'big_pig', 'BIG PIG', 'pig.svg'),
  _derivedTarget(_ball, 'blue_ball', 'BLUE BALL', 'ball.svg'),
  _derivedTarget(_dog, 'my_dog', 'MY DOG', 'dog.svg'),
  _derivedTarget(_goat, 'small_goat', 'SMALL GOAT', 'goat.svg'),
];

final List<GameTarget> _captainsCallTargets = [
  _derivedTarget(_pig, 'i_see_a_pig', 'I SEE A PIG.', 'pig.svg'),
  _derivedTarget(_key, 'i_found_a_key', 'I FOUND A KEY.', 'key.svg'),
  _derivedTarget(_ball, 'this_is_my_ball', 'THIS IS MY BALL.', 'ball.svg'),
  _derivedTarget(_goat, 'i_see_a_goat', 'I SEE A GOAT.', 'goat.svg'),
];

GameTarget _wordTarget(ScreeningWordModel word, String imageName) {
  return GameTarget(
    id: word.id,
    promptText: word.displayWord,
    focusText: word.displayWord,
    imageAssetPath: 'assets/game/words/$imageName',
    assessmentModel: word,
  );
}

GameTarget _derivedTarget(
  ScreeningWordModel source,
  String suffix,
  String promptText,
  String imageName, {
  bool assessFullPrompt = false,
}) {
  return GameTarget(
    id: '${source.id}_$suffix',
    promptText: promptText,
    focusText: source.displayWord,
    imageAssetPath: 'assets/game/words/$imageName',
    assessmentModel: assessFullPrompt
        ? ScreeningWordModel(
            id: '${source.id}_$suffix',
            audioId: source.audioId,
            displayWord: promptText.replaceAll('.', ''),
            phonemeProcess: source.phonemeProcess,
            position: source.position,
            minAge: source.minAge,
            maxAge: source.maxAge,
          )
        : source,
  );
}
