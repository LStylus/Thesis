import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'four_picture_choice_preview.dart' show WordPictureChoice;
import 'template_preview_widgets.dart';

/// Three distinct matches among four buckets. Entirely local caption-only demo.
class SoundBucketPreviewPage extends StatefulWidget {
  const SoundBucketPreviewPage({
    super.key,
    this.randomSeed,
    this.backgroundColor = Colors.white,
    this.backgroundImage,
    this.choices = const [
      WordPictureChoice('Ball', 'assets/game/words/ball.svg'),
      WordPictureChoice('Key', 'assets/game/words/key.svg'),
      WordPictureChoice('Dog', 'assets/game/words/dog.svg'),
      WordPictureChoice('Pig', 'assets/game/words/pig.svg'),
    ],
  });
  static const routeName = '/dev/sound-bucket';
  final int? randomSeed;
  final Color backgroundColor;
  final ImageProvider? backgroundImage;
  final List<WordPictureChoice> choices;
  @override
  State<SoundBucketPreviewPage> createState() => _SoundBucketState();
}

class _SoundBucketState extends State<SoundBucketPreviewPage>
    with SingleTickerProviderStateMixin {
  late final _random = math.Random(widget.randomSeed);
  late List<int> _targets;
  final _filled = <int>{};
  int _round = 0;
  bool _accepted = false, _wrong = false;
  late final _reaction = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  bool get _reduced => MediaQuery.disableAnimationsOf(context);
  bool get _done => _filled.length == 3;
  int get _target => _targets[_round];
  @override
  void initState() {
    super.initState();
    assert(widget.choices.length == 4);
    assert(widget.choices.map((c) => c.word).toSet().length == 4);
    _targets = [0, 1, 2, 3]..shuffle(_random);
  }

  void _match(int bucket, int target) {
    if (_done || _accepted || target != _target || _filled.contains(bucket)) {
      return;
    }
    setState(() {
      _wrong = bucket != target;
      if (!_wrong) {
        _filled.add(bucket);
        _accepted = true;
      }
    });
    if (!_reduced) _reaction.forward(from: 0);
  }

  void _next() {
    if (!_accepted || _done) return;
    _reaction.reset();
    setState(() {
      _round++;
      _accepted = false;
      _wrong = false;
    });
  }

  void _reset() {
    _reaction.reset();
    setState(() {
      _filled.clear();
      _round = 0;
      _accepted = false;
      _wrong = false;
      _targets = [0, 1, 2, 3]..shuffle(_random);
    });
  }

  @override
  void dispose() {
    _reaction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TemplateSurface(
    backgroundColor: widget.backgroundColor,
    backgroundImage: widget.backgroundImage,
    builder: (context, wide, viewport) => Column(
      children: [
        TemplateCaption(
          _done
              ? 'Three buckets filled!'
              : 'Put ${widget.choices[_target].word.toLowerCase()} in its bucket.',
        ),
        const SizedBox(height: 8),
        Text(
          '${_filled.length} of 3 matched',
          key: const ValueKey('bucket-progress'),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: wide && viewport.height < 310 ? 52 : 76,
          child: Center(
            child: _done
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.7, end: 1),
                    duration: Duration(milliseconds: _reduced ? 0 : 500),
                    curve: Curves.easeOutBack,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFE8AE32),
                      size: 52,
                    ),
                  )
                : _accepted
                ? const Icon(
                    Icons.check_circle,
                    color: Color(0xFF339C83),
                    size: 48,
                  )
                : Draggable<int>(
                    key: const ValueKey('bucket-bubble'),
                    data: _target,
                    maxSimultaneousDrags: 1,
                    feedback: Material(
                      color: Colors.transparent,
                      child: _bubble(),
                    ),
                    childWhenDragging: Opacity(opacity: 0.2, child: _bubble()),
                    child: AnimatedBuilder(
                      animation: _reaction,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(
                          _wrong && !_reduced
                              ? math.sin(_reaction.value * math.pi * 4) *
                                    9 *
                                    (1 - _reaction.value)
                              : 0,
                          0,
                        ),
                        child: child,
                      ),
                      child: _bubble(),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, bounds) {
            final columns = wide ? 4 : 2;
            final width = math.min(
              180.0,
              (bounds.maxWidth - 12 * (columns - 1)) / columns,
            );
            final height = wide
                ? math.max(72.0, math.min(168.0, viewport.height * 0.29))
                : 160.0;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (var i = 0; i < 4; i++) _bucket(i, width, height)],
            );
          },
        ),
        const SizedBox(height: 8),
        if (_done)
          FilledButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.replay),
            label: const Text('Play again'),
          )
        else if (_accepted)
          FilledButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next bubble'),
          )
        else
          Semantics(
            liveRegion: true,
            child: Text(
              _wrong
                  ? 'Try another bucket. Your bubble is still here.'
                  : 'Drag the bubble, or tap its matching bucket.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    ),
  );
  Widget _bubble() => Container(
    width: 112,
    height: 70,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(40),
      gradient: const RadialGradient(colors: [Colors.white, Color(0xFFD6F1F7)]),
      border: Border.all(color: const Color(0xFFA8DCE8), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18358696),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Text(
      widget.choices[_target].word,
      style: const TextStyle(
        fontSize: 23,
        color: Color(0xFF244653),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
  Widget _bucket(int index, double width, double height) {
    final filled = _filled.contains(index);
    final choice = widget.choices[index];
    final enabled = !_done && !_accepted && !filled;
    return DragTarget<int>(
      onWillAcceptWithDetails: (_) => enabled,
      onAcceptWithDetails: (details) => _match(index, details.data),
      builder: (context, candidates, rejected) => Semantics(
        label: '${choice.word} bucket${filled ? ', filled' : ''}',
        button: true,
        enabled: enabled,
        excludeSemantics: true,
        onTap: enabled ? () => _match(index, _target) : null,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: filled ? 1 : 0),
          duration: Duration(milliseconds: _reduced ? 0 : 650),
          curve: Curves.easeOutCubic,
          builder: (context, fill, child) => Transform.scale(
            scale: 1 + math.sin(fill * math.pi) * 0.06,
            child: SizedBox(
              width: width,
              height: height,
              child: Material(
                clipBehavior: Clip.antiAlias,
                color: const Color(0xFFF4F7F8),
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                    bottom: Radius.circular(30),
                  ),
                  side: BorderSide(
                    color: candidates.isNotEmpty
                        ? const Color(0xFF58B9C9)
                        : const Color(0xFFB8D5DC),
                    width: 3,
                  ),
                ),
                child: InkWell(
                  key: ValueKey('bucket-${choice.word.toLowerCase()}'),
                  onTap: enabled ? () => _match(index, _target) : null,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: fill * 0.95,
                          widthFactor: 1,
                          child: const ColoredBox(color: Color(0xFFB8EBDE)),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 7,
                        child: Container(
                          height: 4,
                          color: const Color(0xFFB8D5DC),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 18, 14, 6),
                        child: Column(
                          children: [
                            Expanded(child: TemplatePicture(choice.assetPath)),
                            const SizedBox(height: 4),
                            Text(
                              choice.word,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (filled)
                        const Positioned(
                          top: 12,
                          right: 8,
                          child: Icon(
                            Icons.lock,
                            size: 18,
                            color: Color(0xFF237E6D),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
