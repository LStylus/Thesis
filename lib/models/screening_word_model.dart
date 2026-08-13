import '../core/constants/testing_defaults.dart';

class ScreeningWordModel {
  final String id;
  final String audioId;
  final String displayWord;
  final int age;

  const ScreeningWordModel({
    required this.id,
    required this.audioId,
    required this.displayWord,
    required this.age,
  });

  String get audioAssetPath => 'audio/screening/$audioId.mp3';

  static List<ScreeningWordModel> resolveForAge(int age) {
    if (age < 4 || age > 8) {
      throw ArgumentError('Supported age range is 4 to 8.');
    }

    final words = age == 4
        ? age4Words
        : age == 5
        ? age5Words
        : (age == 6 || age == 7)
        ? age6To7Words
        : age8Words;

    return words.take(TestingDefaults.screeningWordsPerAge).toList();
  }

  // AGE 4
  static const List<ScreeningWordModel> age4Words = [
    ScreeningWordModel(id: 'pig_age4', audioId: 'pig', displayWord: 'PIG', age: 4),
    ScreeningWordModel(id: 'ball_age4', audioId: 'ball', displayWord: 'BALL', age: 4),
    ScreeningWordModel(id: 'apple_age4', audioId: 'apple', displayWord: 'APPLE', age: 4),
    ScreeningWordModel(id: 'bunny_age4', audioId: 'bunny', displayWord: 'BUNNY', age: 4),
    ScreeningWordModel(id: 'cup_age4', audioId: 'cup', displayWord: 'CUP', age: 4),
    ScreeningWordModel(id: 'sun_age4_pbmn', audioId: 'sun', displayWord: 'SUN', age: 4),

    ScreeningWordModel(id: 'ten_age4', audioId: 'ten', displayWord: 'TEN', age: 4),
    ScreeningWordModel(id: 'dog_age4', audioId: 'dog', displayWord: 'DOG', age: 4),
    ScreeningWordModel(id: 'water_age4', audioId: 'water', displayWord: 'WATER', age: 4),
    ScreeningWordModel(id: 'ladder_age4', audioId: 'ladder', displayWord: 'LADDER', age: 4),
    ScreeningWordModel(id: 'boat_age4', audioId: 'boat', displayWord: 'BOAT', age: 4),
    ScreeningWordModel(id: 'bed_age4', audioId: 'bed', displayWord: 'BED', age: 4),

    ScreeningWordModel(id: 'key_age4', audioId: 'key', displayWord: 'KEY', age: 4),
    ScreeningWordModel(id: 'goat_age4', audioId: 'goat', displayWord: 'GOAT', age: 4),
    ScreeningWordModel(id: 'cookie_age4', audioId: 'cookie', displayWord: 'COOKIE', age: 4),
    ScreeningWordModel(id: 'tiger_age4', audioId: 'tiger', displayWord: 'TIGER', age: 4),
    ScreeningWordModel(id: 'bike_age4', audioId: 'bike', displayWord: 'BIKE', age: 4),
    ScreeningWordModel(id: 'pig_age4_kg', audioId: 'pig', displayWord: 'PIG', age: 4),

    ScreeningWordModel(id: 'fish_age4', audioId: 'fish', displayWord: 'FISH', age: 4),
    ScreeningWordModel(id: 'whale_age4', audioId: 'whale', displayWord: 'WHALE', age: 4),
    ScreeningWordModel(id: 'elephant_age4', audioId: 'elephant', displayWord: 'ELEPHANT', age: 4),
    ScreeningWordModel(id: 'leaf_age4', audioId: 'leaf', displayWord: 'LEAF', age: 4),
  ];

  // AGE 5
  static const List<ScreeningWordModel> age5Words = [
    ScreeningWordModel(id: 'sun_age5_sz', audioId: 'sun', displayWord: 'SUN', age: 5),
    ScreeningWordModel(id: 'zebra_age5', audioId: 'zebra', displayWord: 'ZEBRA', age: 5),
    ScreeningWordModel(id: 'pencil_age5', audioId: 'pencil', displayWord: 'PENCIL', age: 5),
    ScreeningWordModel(id: 'lizard_age5', audioId: 'lizard', displayWord: 'LIZARD', age: 5),
    ScreeningWordModel(id: 'bus_age5', audioId: 'bus', displayWord: 'BUS', age: 5),
    ScreeningWordModel(id: 'cheese_age5', audioId: 'cheese', displayWord: 'CHEESE', age: 5),

    ScreeningWordModel(id: 'yarn_age5', audioId: 'yarn', displayWord: 'YARN', age: 5),
    ScreeningWordModel(id: 'hat_age5', audioId: 'hat', displayWord: 'HAT', age: 5),
    ScreeningWordModel(id: 'yoyo_age5', audioId: 'yoyo', displayWord: 'YOYO', age: 5),

    ScreeningWordModel(id: 'shoe_age5', audioId: 'shoe', displayWord: 'SHOE', age: 5),
    ScreeningWordModel(id: 'flashlight_age5', audioId: 'flashlight', displayWord: 'FLASHLIGHT', age: 5),
    ScreeningWordModel(id: 'fish_age5_sh', audioId: 'fish', displayWord: 'FISH', age: 5),

    ScreeningWordModel(id: 'spider_age5', audioId: 'spider', displayWord: 'SPIDER', age: 5),
    ScreeningWordModel(id: 'star_age5', audioId: 'star', displayWord: 'STAR', age: 5),

    ScreeningWordModel(id: 'blue_age5', audioId: 'blue', displayWord: 'BLUE', age: 5),
    ScreeningWordModel(id: 'plane_age5', audioId: 'plane', displayWord: 'PLANE', age: 5),
  ];

  // AGE 6–7
  static const List<ScreeningWordModel> age6To7Words = [
    ScreeningWordModel(id: 'lion_age67', audioId: 'lion', displayWord: 'LION', age: 6),
    ScreeningWordModel(id: 'balloon_age67', audioId: 'balloon', displayWord: 'BALLOON', age: 6),
    ScreeningWordModel(id: 'bell_age67', audioId: 'bell', displayWord: 'BELL', age: 6),

    ScreeningWordModel(id: 'rock_age67', audioId: 'rock', displayWord: 'ROCK', age: 6),
    ScreeningWordModel(id: 'mirror_age67', audioId: 'mirror', displayWord: 'MIRROR', age: 6),
    ScreeningWordModel(id: 'star_age67_r', audioId: 'star', displayWord: 'STAR', age: 6),

    ScreeningWordModel(id: 'volcano_age67', audioId: 'volcano', displayWord: 'VOLCANO', age: 6),
    ScreeningWordModel(id: 'seven_age67', audioId: 'seven', displayWord: 'SEVEN', age: 6),
    ScreeningWordModel(id: 'glove_age67', audioId: 'glove', displayWord: 'GLOVE', age: 6),

    ScreeningWordModel(id: 'chair_age67', audioId: 'chair', displayWord: 'CHAIR', age: 6),
    ScreeningWordModel(id: 'jeep_age67', audioId: 'jeep', displayWord: 'JEEP', age: 6),
    ScreeningWordModel(id: 'kitchen_age67', audioId: 'kitchen', displayWord: 'KITCHEN', age: 6),
    ScreeningWordModel(id: 'orange_age67', audioId: 'orange', displayWord: 'ORANGE', age: 6),
    ScreeningWordModel(id: 'watch_age67', audioId: 'watch', displayWord: 'WATCH', age: 6),
    ScreeningWordModel(id: 'bridge_age67', audioId: 'bridge', displayWord: 'BRIDGE', age: 6),

    ScreeningWordModel(id: 'frog_age67', audioId: 'frog', displayWord: 'FROG', age: 6),
    ScreeningWordModel(id: 'truck_age67', audioId: 'truck', displayWord: 'TRUCK', age: 6),
  ];

  // AGE 8
  static const List<ScreeningWordModel> age8Words = [
    ScreeningWordModel(id: 'thumb_age8', audioId: 'thumb', displayWord: 'THUMB', age: 8),
    ScreeningWordModel(id: 'toothbrush_age8', audioId: 'toothbrush', displayWord: 'TOOTHBRUSH', age: 8),
    ScreeningWordModel(id: 'mouth_age8', audioId: 'mouth', displayWord: 'MOUTH', age: 8),

    ScreeningWordModel(id: 'they_age8', audioId: 'they', displayWord: 'THEY', age: 8),

    ScreeningWordModel(id: 'feather_age8', audioId: 'feather', displayWord: 'FEATHER', age: 8),
    ScreeningWordModel(id: 'smooth_age8', audioId: 'smooth', displayWord: 'SMOOTH', age: 8),

    ScreeningWordModel(id: 'treasure_age8', audioId: 'treasure', displayWord: 'TREASURE', age: 8),

    ScreeningWordModel(id: 'helicopter_age8', audioId: 'helicopter', displayWord: 'HELICOPTER', age: 8),
    ScreeningWordModel(id: 'vegetable_age8', audioId: 'vegetable', displayWord: 'VEGETABLE', age: 8),
    ScreeningWordModel(id: 'spaghetti_age8', audioId: 'spaghetti', displayWord: 'SPAGHETTI', age: 8),
  ];
}
