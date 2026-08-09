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
    ScreeningWordModel(id: 'pig_age4_initial', audioId: 'pig', displayWord: 'PIG', age: 4),
    ScreeningWordModel(id: 'ball_age4_initial', audioId: 'ball', displayWord: 'BALL', age: 4),
    ScreeningWordModel(id: 'apple_age4_medial', audioId: 'apple', displayWord: 'APPLE', age: 4),
    ScreeningWordModel(id: 'bunny_age4_medial', audioId: 'bunny', displayWord: 'BUNNY', age: 4),
    ScreeningWordModel(id: 'cup_age4_final', audioId: 'cup', displayWord: 'CUP', age: 4),
    ScreeningWordModel(id: 'sun_age4_final_pbmn', audioId: 'sun', displayWord: 'SUN', age: 4),

    ScreeningWordModel(id: 'ten_age4_initial', audioId: 'ten', displayWord: 'TEN', age: 4),
    ScreeningWordModel(id: 'dog_age4_initial', audioId: 'dog', displayWord: 'DOG', age: 4),
    ScreeningWordModel(id: 'water_age4_medial', audioId: 'water', displayWord: 'WATER', age: 4),
    ScreeningWordModel(id: 'ladder_age4_medial', audioId: 'ladder', displayWord: 'LADDER', age: 4),
    ScreeningWordModel(id: 'boat_age4_final', audioId: 'boat', displayWord: 'BOAT', age: 4),
    ScreeningWordModel(id: 'bed_age4_final', audioId: 'bed', displayWord: 'BED', age: 4),

    ScreeningWordModel(id: 'key_age4_initial', audioId: 'key', displayWord: 'KEY', age: 4),
    ScreeningWordModel(id: 'goat_age4_initial', audioId: 'goat', displayWord: 'GOAT', age: 4),
    ScreeningWordModel(id: 'cookie_age4_medial', audioId: 'cookie', displayWord: 'COOKIE', age: 4),
    ScreeningWordModel(id: 'tiger_age4_medial', audioId: 'tiger', displayWord: 'TIGER', age: 4),
    ScreeningWordModel(id: 'bike_age4_final', audioId: 'bike', displayWord: 'BIKE', age: 4),
    ScreeningWordModel(id: 'pig_age4_final_kg', audioId: 'pig', displayWord: 'PIG', age: 4),

    ScreeningWordModel(id: 'fish_age4_initial', audioId: 'fish', displayWord: 'FISH', age: 4),
    ScreeningWordModel(id: 'whale_age4_initial', audioId: 'whale', displayWord: 'WHALE', age: 4),
    ScreeningWordModel(id: 'elephant_age4_medial', audioId: 'elephant', displayWord: 'ELEPHANT', age: 4),
    ScreeningWordModel(id: 'leaf_age4_final', audioId: 'leaf', displayWord: 'LEAF', age: 4),
  ];

  // AGE 5
  static const List<ScreeningWordModel> age5Words = [
    ScreeningWordModel(id: 'sun_age5_initial_sz', audioId: 'sun', displayWord: 'SUN', age: 5),
    ScreeningWordModel(id: 'zebra_age5_initial', audioId: 'zebra', displayWord: 'ZEBRA', age: 5),
    ScreeningWordModel(id: 'pencil_age5_medial', audioId: 'pencil', displayWord: 'PENCIL', age: 5),
    ScreeningWordModel(id: 'lizard_age5_medial', audioId: 'lizard', displayWord: 'LIZARD', age: 5),
    ScreeningWordModel(id: 'bus_age5_final', audioId: 'bus', displayWord: 'BUS', age: 5),
    ScreeningWordModel(id: 'cheese_age5_final', audioId: 'cheese', displayWord: 'CHEESE', age: 5),

    ScreeningWordModel(id: 'yarn_age5_initial', audioId: 'yarn', displayWord: 'YARN', age: 5),
    ScreeningWordModel(id: 'hat_age5_initial', audioId: 'hat', displayWord: 'HAT', age: 5),
    ScreeningWordModel(id: 'yoyo_age5_medial', audioId: 'yoyo', displayWord: 'YOYO', age: 5),

    ScreeningWordModel(id: 'shoe_age5_initial', audioId: 'shoe', displayWord: 'SHOE', age: 5),
    ScreeningWordModel(id: 'flashlight_age5_medial', audioId: 'flashlight', displayWord: 'FLASHLIGHT', age: 5),
    ScreeningWordModel(id: 'fish_age5_final_sh', audioId: 'fish', displayWord: 'FISH', age: 5),

    ScreeningWordModel(id: 'spider_age5_initial', audioId: 'spider', displayWord: 'SPIDER', age: 5),
    ScreeningWordModel(id: 'star_age5_initial', audioId: 'star', displayWord: 'STAR', age: 5),

    ScreeningWordModel(id: 'blue_age5_initial', audioId: 'blue', displayWord: 'BLUE', age: 5),
    ScreeningWordModel(id: 'plane_age5_initial', audioId: 'plane', displayWord: 'PLANE', age: 5),
  ];

  // AGE 6–7
  static const List<ScreeningWordModel> age6To7Words = [
    ScreeningWordModel(id: 'lion_age67_initial', audioId: 'lion', displayWord: 'LION', age: 6),
    ScreeningWordModel(id: 'balloon_age67_medial', audioId: 'balloon', displayWord: 'BALLOON', age: 6),
    ScreeningWordModel(id: 'bell_age67_final', audioId: 'bell', displayWord: 'BELL', age: 6),

    ScreeningWordModel(id: 'rock_age67_initial', audioId: 'rock', displayWord: 'ROCK', age: 6),
    ScreeningWordModel(id: 'mirror_age67_medial', audioId: 'mirror', displayWord: 'MIRROR', age: 6),
    ScreeningWordModel(id: 'star_age67_final_r', audioId: 'star', displayWord: 'STAR', age: 6),

    ScreeningWordModel(id: 'volcano_age67_initial', audioId: 'volcano', displayWord: 'VOLCANO', age: 6),
    ScreeningWordModel(id: 'seven_age67_medial', audioId: 'seven', displayWord: 'SEVEN', age: 6),
    ScreeningWordModel(id: 'glove_age67_final', audioId: 'glove', displayWord: 'GLOVE', age: 6),

    ScreeningWordModel(id: 'chair_age67_initial', audioId: 'chair', displayWord: 'CHAIR', age: 6),
    ScreeningWordModel(id: 'jeep_age67_initial', audioId: 'jeep', displayWord: 'JEEP', age: 6),
    ScreeningWordModel(id: 'kitchen_age67_medial', audioId: 'kitchen', displayWord: 'KITCHEN', age: 6),
    ScreeningWordModel(id: 'orange_age67_medial', audioId: 'orange', displayWord: 'ORANGE', age: 6),
    ScreeningWordModel(id: 'watch_age67_final', audioId: 'watch', displayWord: 'WATCH', age: 6),
    ScreeningWordModel(id: 'bridge_age67_final', audioId: 'bridge', displayWord: 'BRIDGE', age: 6),

    ScreeningWordModel(id: 'frog_age67_initial', audioId: 'frog', displayWord: 'FROG', age: 6),
    ScreeningWordModel(id: 'truck_age67_initial', audioId: 'truck', displayWord: 'TRUCK', age: 6),
  ];

  // AGE 8
  static const List<ScreeningWordModel> age8Words = [
    ScreeningWordModel(id: 'thumb_age8_initial', audioId: 'thumb', displayWord: 'THUMB', age: 8),
    ScreeningWordModel(id: 'toothbrush_age8_medial', audioId: 'toothbrush', displayWord: 'TOOTHBRUSH', age: 8),
    ScreeningWordModel(id: 'mouth_age8_final', audioId: 'mouth', displayWord: 'MOUTH', age: 8),

    ScreeningWordModel(id: 'they_age8_initial', audioId: 'they', displayWord: 'THEY', age: 8),

    ScreeningWordModel(id: 'feather_age8_medial', audioId: 'feather', displayWord: 'FEATHER', age: 8),
    ScreeningWordModel(id: 'smooth_age8_final', audioId: 'smooth', displayWord: 'SMOOTH', age: 8),

    ScreeningWordModel(id: 'treasure_age8_medial', audioId: 'treasure', displayWord: 'TREASURE', age: 8),

    ScreeningWordModel(id: 'helicopter_age8_initial', audioId: 'helicopter', displayWord: 'HELICOPTER', age: 8),
    ScreeningWordModel(id: 'vegetable_age8_medial', audioId: 'vegetable', displayWord: 'VEGETABLE', age: 8),
    ScreeningWordModel(id: 'spaghetti_age8_final', audioId: 'spaghetti', displayWord: 'SPAGHETTI', age: 8),
  ];
}
