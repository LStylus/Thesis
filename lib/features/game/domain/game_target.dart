import '../../../models/screening_word_model.dart';

/// Reusable speech content, not a mechanic's choices, pieces, or answer key.
class GameTarget {
  final String id;
  final String promptText;
  final String focusText;
  final String? imageAssetPath;
  final String? audioAssetPath;
  final ScreeningWordModel assessmentModel;
  final String? targetSound;
  final String? soundPosition;

  /// Source speech unit (e.g. word or phrase), never a five-stage assignment.
  final String? contentUnit;

  const GameTarget({
    required this.id,
    required this.promptText,
    required this.focusText,
    required this.assessmentModel,
    this.imageAssetPath,
    this.audioAssetPath,
    this.targetSound,
    this.soundPosition,
    this.contentUnit,
  });
}
