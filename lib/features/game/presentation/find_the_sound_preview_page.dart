import 'package:flutter/material.dart';

import 'four_picture_choice_preview.dart';

/// Initial-sound recognition using authored phonemes, not letter matching.
/// Artwork and prompts remain local placeholders; no audio or speech services.
class FindTheSoundPreviewPage extends StatelessWidget {
  const FindTheSoundPreviewPage({
    super.key,
    this.backgroundColor = Colors.white,
    this.backgroundImage,
    this.choices = const [
      WordPictureChoice('Ball', 'assets/game/words/ball.svg'),
      WordPictureChoice('Key', 'assets/game/words/key.svg'),
      WordPictureChoice('Dog', 'assets/game/words/dog.svg'),
      WordPictureChoice('Pig', 'assets/game/words/pig.svg'),
    ],
    this.rounds = const [
      PictureRecognitionRound(
        caption: 'Which picture starts with /b/?',
        answerIndex: 0,
        successCaption: 'Ball starts with /b/!',
      ),
      PictureRecognitionRound(
        caption: 'Which picture starts with /k/?',
        answerIndex: 1,
        successCaption: 'Key starts with /k/!',
      ),
      PictureRecognitionRound(
        caption: 'Which picture starts with /d/?',
        answerIndex: 2,
        successCaption: 'Dog starts with /d/!',
      ),
    ],
    this.randomSeed,
  });

  static const routeName = '/dev/find-the-sound';
  final Color backgroundColor;
  final ImageProvider? backgroundImage;
  final List<WordPictureChoice> choices;

  /// Replace together with choices to preserve one correct picture per prompt.
  final List<PictureRecognitionRound> rounds;
  final int? randomSeed;

  @override
  Widget build(BuildContext context) => FourPictureChoicePreview(
    backgroundColor: backgroundColor,
    backgroundImage: backgroundImage,
    choices: choices,
    rounds: rounds,
    randomSeed: randomSeed,
    keyPrefix: 'sound',
    nextLabel: 'Next sound',
    completionTitle: 'Three sounds found!',
  );
}
