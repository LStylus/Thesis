import 'package:flutter/material.dart';

import 'four_picture_choice_preview.dart';
export 'four_picture_choice_preview.dart' show WordPictureChoice;

/// Word recognition keeps the same replaceable artwork interface.
class FindTheWordPreviewPage extends StatelessWidget {
  const FindTheWordPreviewPage({
    super.key,
    this.backgroundColor = Colors.white,
    this.backgroundImage,
    this.choices = const [
      WordPictureChoice('Ball', 'assets/game/words/ball.svg'),
      WordPictureChoice('Key', 'assets/game/words/key.svg'),
      WordPictureChoice('Dog', 'assets/game/words/dog.svg'),
      WordPictureChoice('Pig', 'assets/game/words/pig.svg'),
    ],
    this.randomSeed,
  });
  static const routeName = '/dev/find-the-word';
  final Color backgroundColor;
  final ImageProvider? backgroundImage;

  /// Four distinct pictures; the first three are the target words.
  final List<WordPictureChoice> choices;
  final int? randomSeed;

  @override
  Widget build(BuildContext context) => FourPictureChoicePreview(
    backgroundColor: backgroundColor,
    backgroundImage: backgroundImage,
    choices: choices,
    randomSeed: randomSeed,
    rounds: [
      for (var i = 0; i < 3; i++)
        PictureRecognitionRound(
          caption: 'Find the ${choices[i].word.toLowerCase()}.',
          answerIndex: i,
        ),
    ],
    nextLabel: 'Next word',
    completionTitle: 'Three words found!',
  );
}
