import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Replaceable artwork and labels for the local four-choice template.
class WordPictureChoice {
  const WordPictureChoice(this.word, this.assetPath);
  final String word;
  final String assetPath;
}

/// Authored sound/word prompts and answer keys; never infer phonemes from spelling.
class PictureRecognitionRound {
  const PictureRecognitionRound({
    required this.caption,
    required this.answerIndex,
    this.successCaption = 'You found it!',
  });
  final String caption;
  final int answerIndex;
  final String successCaption;
}

/// Caption-only recognition demo. No microphone, account or score writes.
class FourPictureChoicePreview extends StatefulWidget {
  const FourPictureChoicePreview({
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
    required this.rounds,
    required this.nextLabel,
    required this.completionTitle,
    this.keyPrefix = 'word',
  });

  final List<PictureRecognitionRound> rounds;
  final String nextLabel;
  final String completionTitle;
  final String keyPrefix;
  final Color backgroundColor;
  final ImageProvider? backgroundImage;

  /// Four distinct pictures with authored, unambiguous round answer keys.
  final List<WordPictureChoice> choices;
  final int? randomSeed;

  @override
  State<FourPictureChoicePreview> createState() => _FourPictureChoiceState();
}

class _FourPictureChoiceState extends State<FourPictureChoicePreview>
    with SingleTickerProviderStateMixin {
  static const _ink = Color(0xFF244653);
  late final _random = math.Random(widget.randomSeed);
  late final AnimationController _reaction =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      )..addStatusListener((_) {
        if (mounted) setState(() {});
      });
  late List<int> _order;
  int _round = 0, _found = 0, _boardVersion = 0;
  int? _selected;
  bool _correct = false;
  bool get _done => _found == 3;
  bool get _reduced => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    assert(widget.choices.length == 4);
    assert(widget.rounds.length == 3);
    assert(
      widget.rounds.every(
        (round) => round.answerIndex >= 0 && round.answerIndex < 4,
      ),
    );
    assert(widget.choices.map((choice) => choice.word).toSet().length == 4);
    _shuffle();
  }

  void _shuffle() => _order = [0, 1, 2, 3]..shuffle(_random);

  void _choose(int index) {
    if (_correct || _done || _reaction.isAnimating) return;
    setState(() {
      _selected = index;
      _correct = index == widget.rounds[_round].answerIndex;
      if (_correct) _found++;
    });
    if (!_reduced) _reaction.forward(from: 0);
  }

  void _next() {
    if (!_correct || _done) return;
    _reaction.reset();
    setState(() {
      _round++;
      _correct = false;
      _selected = null;
      _boardVersion++;
      _shuffle();
    });
  }

  void _replay() {
    _reaction.reset();
    setState(() {
      _round = _found = 0;
      _correct = false;
      _selected = null;
      _boardVersion++;
      _shuffle();
    });
  }

  @override
  void dispose() {
    _reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: widget.backgroundColor,
    body: DecoratedBox(
      decoration: BoxDecoration(
        image: widget.backgroundImage == null
            ? null
            : DecorationImage(
                image: widget.backgroundImage!,
                fit: BoxFit.cover,
              ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, bounds) {
            final wide = bounds.maxWidth > bounds.maxHeight;
            return SingleChildScrollView(
              child: SizedBox(
                height: math.max(bounds.maxHeight, wide ? 270 : 480),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            AnimatedScale(
                              scale: i < _found ? 1.12 : 1,
                              duration: Duration(
                                milliseconds: _reduced ? 0 : 350,
                              ),
                              curve: Curves.easeOutBack,
                              child: Icon(
                                i < _found
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: i < _found
                                    ? const Color(0xFFE8AE32)
                                    : const Color(0xFFBCCBD1),
                                size: 26,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Text(
                            '$_found of 3 correct',
                            key: ValueKey('${widget.keyPrefix}-progress'),
                            style: const TextStyle(color: _ink),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: Duration(milliseconds: _reduced ? 0 : 300),
                          child: _done ? _completion() : _board(wide),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _board(bool wide) => Column(
    key: ValueKey('${widget.keyPrefix}-board'),
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F8FA),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Semantics(
          liveRegion: true,
          child: Column(
            children: [
              const Text(
                'TEMPORARY CAPTION',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  color: Color(0xFF677D86),
                ),
              ),
              AnimatedSwitcher(
                duration: Duration(milliseconds: _reduced ? 0 : 250),
                child: Text(
                  widget.rounds[_round].caption,
                  key: ValueKey('${widget.keyPrefix}-caption-$_round'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: LayoutBuilder(
          builder: (context, bounds) {
            const gap = 14.0;
            final columns = wide ? 4 : 2;
            final rows = wide ? 1 : 2;
            final size = math.max(
              48.0,
              math.min(
                220.0,
                math.min(
                  (bounds.maxWidth - gap * (columns - 1)) / columns,
                  (bounds.maxHeight - gap * (rows - 1)) / rows,
                ),
              ),
            );
            return Center(
              child: TweenAnimationBuilder<double>(
                key: ValueKey('${widget.keyPrefix}-entrance-$_boardVersion'),
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: _reduced ? 0 : 450),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - value)),
                    child: child,
                  ),
                ),
                child: SizedBox(
                  width: size * columns + gap * (columns - 1),
                  child: Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final index in _order) _choice(index, size),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 6),
      SizedBox(
        height: 44,
        child: _correct
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.rounds[_round].successCaption,
                      style: const TextStyle(
                        color: Color(0xFF237E6D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _next,
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(widget.nextLabel),
                  ),
                ],
              )
            : Center(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    _selected == null
                        ? 'Tap the matching picture.'
                        : 'Not quite. Try another picture.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _ink),
                  ),
                ),
              ),
      ),
    ],
  );

  Widget _choice(int index, double size) {
    final selected = _selected == index;
    final choice = widget.choices[index];
    final locked = _correct || _reaction.isAnimating;
    return AnimatedBuilder(
      animation: _reaction,
      builder: (context, child) {
        final pulse = math.sin(_reaction.value * math.pi);
        return Transform.translate(
          offset: Offset(
            selected && !_correct && !_reduced
                ? math.sin(_reaction.value * math.pi * 4) *
                      6 *
                      (1 - _reaction.value)
                : 0,
            0,
          ),
          child: Transform.scale(
            scale: selected && _correct && !_reduced ? 1 + pulse * 0.06 : 1,
            child: child,
          ),
        );
      },
      child: Semantics(
        label: 'Choose ${choice.word}',
        button: true,
        enabled: !locked,
        excludeSemantics: true,
        onTap: locked ? null : () => _choose(index),
        child: SizedBox(
          width: size,
          height: size,
          child: Material(
            color: selected
                ? (_correct ? const Color(0xFFE6F6EE) : const Color(0xFFFFF5E3))
                : const Color(0xFFF4F6F7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                width: selected ? 3 : 1.5,
                color: selected
                    ? (_correct
                          ? const Color(0xFF52A88A)
                          : const Color(0xFFE7BF78))
                    : const Color(0xFFDCE5E9),
              ),
            ),
            child: InkWell(
              key: ValueKey(
                '${widget.keyPrefix}-choice-${choice.word.toLowerCase()}',
              ),
              borderRadius: BorderRadius.circular(20),
              onTap: locked ? null : () => _choose(index),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.15),
                      child: choice.assetPath.toLowerCase().endsWith('.svg')
                          ? SvgPicture.asset(
                              choice.assetPath,
                              fit: BoxFit.contain,
                            )
                          : Image.asset(choice.assetPath, fit: BoxFit.contain),
                    ),
                  ),
                  if (selected && _correct)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: Icon(
                        Icons.check_circle,
                        color: Color(0xFF237E6D),
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _completion() => Center(
    key: ValueKey('${widget.keyPrefix}-completion'),
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1),
      duration: Duration(milliseconds: _reduced ? 0 : 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 64, color: Color(0xFFE8AE32)),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              widget.completionTitle,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ),
          const Text('Great matching!', style: TextStyle(color: _ink)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _replay,
            icon: const Icon(Icons.replay),
            label: const Text('Play again'),
          ),
        ],
      ),
    ),
  );
}
