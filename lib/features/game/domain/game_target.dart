import '../../../models/screening_word_model.dart';

class GameTarget {
  final String id;
  final String promptText;
  final String focusText;
  final String? imageAssetPath;
  final ScreeningWordModel assessmentModel;
  final List<String> pieces;
  final List<String> options;
  final int correctOptionIndex;

  const GameTarget({
    required this.id,
    required this.promptText,
    required this.focusText,
    required this.assessmentModel,
    this.imageAssetPath,
    this.pieces = const [],
    this.options = const [],
    this.correctOptionIndex = 0,
  });
}
