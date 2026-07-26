import '../../../models/screening_word_model.dart';

class GameTarget {
  final String id;
  final String promptText;
  final String focusText;
  final String? imageAssetPath;
  final ScreeningWordModel assessmentModel;

  const GameTarget({
    required this.id,
    required this.promptText,
    required this.focusText,
    required this.assessmentModel,
    this.imageAssetPath,
  });
}
