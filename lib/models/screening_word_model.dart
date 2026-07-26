import '../core/constants/testing_defaults.dart';

part 'screening_word_bank.dart';

enum ScreeningWordPosition { initial, medial, finalPosition }

extension ScreeningWordPositionLabel on ScreeningWordPosition {
  String get label {
    switch (this) {
      case ScreeningWordPosition.initial:
        return 'Initial';
      case ScreeningWordPosition.medial:
        return 'Medial';
      case ScreeningWordPosition.finalPosition:
        return 'Final';
    }
  }
}

class ScreeningWordModel {
  final String id;
  final String audioId;
  final String displayWord;
  final String phonemeProcess;
  final ScreeningWordPosition position;
  final int minAge;
  final int maxAge;

  const ScreeningWordModel({
    required this.id,
    required this.audioId,
    required this.displayWord,
    required this.phonemeProcess,
    required this.position,
    required this.minAge,
    required this.maxAge,
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

    // Production behavior:
    // return words;
    return words.take(TestingDefaults.screeningWordsPerAge).toList();
  }

  static const List<ScreeningWordModel> age4Words = _age4Words;
  static const List<ScreeningWordModel> age5Words = _age5Words;
  static const List<ScreeningWordModel> age6To7Words = _age6To7Words;
  static const List<ScreeningWordModel> age8Words = _age8Words;
}
