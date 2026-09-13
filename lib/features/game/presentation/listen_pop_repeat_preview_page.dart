import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'template_preview_widgets.dart';

class RepeatBubbleTarget {
  const RepeatBubbleTarget(this.word, this.pictureAsset);
  final String word;
  final String pictureAsset;
}

enum _RepeatPhase { choose, pop, model, speak, echo, reviewed }

/// Caption-only storyboard. Previewed IDs are not speech or learning results.
class ListenPopRepeatPreviewPage extends StatefulWidget {
  const ListenPopRepeatPreviewPage({
    super.key,
    this.backgroundColor = Colors.white,
    this.backgroundImage,
    this.bubbleColor = const Color(0xFFDDF4F7),
    this.targets = const [
      RepeatBubbleTarget('Ball', 'assets/game/words/ball.svg'),
      RepeatBubbleTarget('Key', 'assets/game/words/key.svg'),
      RepeatBubbleTarget('Dog', 'assets/game/words/dog.svg'),
    ],
  });
  static const routeName = '/dev/listen-pop-repeat';
  final Color backgroundColor;
  final ImageProvider? backgroundImage;
  final Color bubbleColor;
  final List<RepeatBubbleTarget> targets;

  @override
  State<ListenPopRepeatPreviewPage> createState() => _ListenPopRepeatState();
}

class _ListenPopRepeatState extends State<ListenPopRepeatPreviewPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _float, _effect;
  final _previewed = <int>{};
  _RepeatPhase _phase = _RepeatPhase.choose;
  int? _active;
  bool _paused = false, _foreground = true, _reduced = false;
  bool get _finished => _previewed.length == widget.targets.length;
  String get _word => widget.targets[_active!].word.toLowerCase();

  @override
  void initState() {
    super.initState();
    assert(widget.targets.length == 3);
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _effect = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        setState(() {
          if (_phase == _RepeatPhase.pop) _phase = _RepeatPhase.model;
          if (_phase == _RepeatPhase.echo) _phase = _RepeatPhase.reviewed;
        });
      });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    _syncMotion();
    if (_reduced && !_paused && _foreground && _effect.isAnimating) {
      _effect.value = 1;
    }
  }

  void _syncMotion() {
    final moving =
        !_reduced &&
        !_paused &&
        _foreground &&
        _phase == _RepeatPhase.choose &&
        !_finished;
    if (moving && !_float.isAnimating) _float.repeat();
    if (!moving) _float.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _effect.stop();
      setState(() => _paused = true);
    }
    _syncMotion();
  }

  void _togglePause() {
    if (!_foreground) return;
    setState(() => _paused = !_paused);
    if (_paused) {
      _effect.stop();
    } else if (_phase == _RepeatPhase.pop || _phase == _RepeatPhase.echo) {
      if (_reduced) {
        _effect.value = 1;
      } else {
        _effect.forward();
      }
    }
    _syncMotion();
  }

  void _animate(_RepeatPhase phase, int milliseconds) {
    setState(() => _phase = phase);
    _effect.duration = Duration(milliseconds: milliseconds);
    _effect.reset();
    _syncMotion();
    if (_reduced) {
      _effect.value = 1;
    } else {
      _effect.forward();
    }
  }

  void _pop(int id) {
    if (_paused ||
        !_foreground ||
        _phase != _RepeatPhase.choose ||
        _previewed.contains(id)) {
      return;
    }
    _active = id;
    _animate(_RepeatPhase.pop, 450);
  }

  void _reset() {
    _effect.reset();
    setState(() {
      _active = null;
      _previewed.clear();
      _phase = _RepeatPhase.choose;
      _paused = !_foreground;
    });
    _syncMotion();
  }

  void _next() {
    if (_paused || !_foreground || _phase != _RepeatPhase.reviewed) return;
    setState(() {
      _previewed.add(_active!);
      _active = null;
      _phase = _RepeatPhase.choose;
    });
    _syncMotion();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _float.dispose();
    _effect.dispose();
    super.dispose();
  }

  String get _caption => _paused
      ? 'Preview paused. Resume when you are ready.'
      : switch (_phase) {
          _RepeatPhase.choose =>
            _finished
                ? 'All three bubble previews finished!'
                : 'Pop a picture bubble. See its word, then repeat.',
          _RepeatPhase.pop => 'Pop! Let’s see the picture.',
          _RepeatPhase.model => 'This is a $_word.',
          _RepeatPhase.speak => 'Your turn: say $_word.',
          _RepeatPhase.echo => 'Say $_word. These bars are animation only.',
          _RepeatPhase.reviewed =>
            'Speaking animation finished. No speech was checked.',
        };

  @override
  Widget build(BuildContext context) => TemplateSurface(
    backgroundColor: widget.backgroundColor,
    backgroundImage: widget.backgroundImage,
    builder: (context, wide, viewport) {
      final compact = wide && viewport.height < 400;
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_previewed.length} of 3 preview turns finished',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF677D86),
                  ),
                ),
              ),
              IconButton(
                tooltip: _paused ? 'Resume preview' : 'Pause preview',
                onPressed: _togglePause,
                visualDensity: VisualDensity.compact,
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause, size: 20),
              ),
              IconButton(
                tooltip: 'Restart bubble preview',
                onPressed: _reset,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.replay, size: 20),
              ),
            ],
          ),
          TemplateCaption(_caption),
          const SizedBox(height: 8),
          _field(compact ? 140 : 280),
          const SizedBox(height: 6),
          _controls(),
          const SizedBox(height: 4),
          const Text(
            'Template only · No audio, recording, speech checking or saved progress.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF677D86)),
          ),
        ],
      );
    },
  );

  Widget _controls() {
    if (_paused) {
      return FilledButton(
        onPressed: _togglePause,
        child: const Text('Resume preview'),
      );
    }
    return switch (_phase) {
      _RepeatPhase.choose =>
        _finished
            ? FilledButton(
                onPressed: _reset,
                child: const Text('Replay bubble preview'),
              )
            : const Text(
                'Choose any bubble',
                style: TextStyle(color: Color(0xFF677D86)),
              ),
      _RepeatPhase.pop => const Text('Revealing picture…'),
      _RepeatPhase.model => FilledButton.icon(
        onPressed: () => setState(() => _phase = _RepeatPhase.speak),
        icon: const Icon(Icons.arrow_forward, size: 18),
        label: const Text('Your turn'),
      ),
      _RepeatPhase.speak => Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          FilledButton.icon(
            onPressed: () => _animate(_RepeatPhase.echo, 2200),
            icon: const Icon(Icons.graphic_eq, size: 18),
            label: const Text('Preview speaking animation'),
          ),
          TextButton(
            onPressed: () => setState(() => _phase = _RepeatPhase.model),
            child: const Text('Show word caption'),
          ),
        ],
      ),
      _RepeatPhase.echo => const Text('Animation only · Microphone is off'),
      _RepeatPhase.reviewed => Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          FilledButton(
            onPressed: _next,
            child: Text(
              _previewed.length == 2 ? 'Finish preview' : 'Next bubble',
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _phase = _RepeatPhase.speak),
            child: const Text('Repeat this word'),
          ),
        ],
      ),
    };
  }

  Widget _field(double height) => SizedBox(
    key: const ValueKey('repeat-field'),
    height: height,
    width: double.infinity,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: LayoutBuilder(
        builder: (context, bounds) {
          final size = math.min(
            110.0,
            math.min(height * .6, bounds.maxWidth / 3 - 12),
          );
          return Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: widget.backgroundColor)),
              ExcludeSemantics(
                excluding: _active != null || _paused,
                child: IgnorePointer(
                  ignoring: _active != null || _paused,
                  child: AnimatedBuilder(
                    animation: _float,
                    builder: (_, _) => Stack(
                      children: [
                        for (var i = 0; i < widget.targets.length; i++)
                          if (!_previewed.contains(i) && i != _active)
                            Positioned(
                              left:
                                  (bounds.maxWidth - size) *
                                  [0.06, 0.5, 0.94][i],
                              top:
                                  (height - size - 16) * [0.25, 0.8, 0.15][i] +
                                  8 +
                                  (_reduced
                                      ? 0
                                      : math.sin(
                                              _float.value * math.pi * 2 +
                                                  i * 2,
                                            ) *
                                            6),
                              width: size,
                              height: size,
                              child: _bubble(i),
                            ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_active != null) ...[
                const Positioned.fill(
                  child: ColoredBox(
                    key: ValueKey('repeat-dim'),
                    color: Color(0xB3243541),
                  ),
                ),
                Center(
                  child: AnimatedBuilder(
                    animation: _effect,
                    builder: (_, child) {
                      final popping = _phase == _RepeatPhase.pop;
                      final t = popping ? _effect.value : 1.0;
                      return Transform.scale(
                        scale: _reduced
                            ? 1
                            : .65 + .35 * Curves.easeOutBack.transform(t),
                        child: CustomPaint(
                          foregroundPainter: popping ? _PopRings(t) : null,
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: const ValueKey('repeat-focus'),
                      width: height * .78,
                      height: height * .78,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Semantics(
                              image: true,
                              label: widget.targets[_active!].word,
                              child: TemplatePicture(
                                widget.targets[_active!].pictureAsset,
                              ),
                            ),
                          ),
                          if (_phase == _RepeatPhase.echo)
                            SizedBox(
                              height: 22,
                              child: AnimatedBuilder(
                                animation: _effect,
                                builder: (_, _) => Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    for (var i = 0; i < 9; i++)
                                      Container(
                                        width: 4,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        height: _reduced
                                            ? 6
                                            : 5 +
                                                  16 *
                                                      math
                                                          .sin(
                                                            _effect.value *
                                                                    math.pi *
                                                                    10 +
                                                                i * .7,
                                                          )
                                                          .abs(),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF55B8B5),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              if (_finished)
                const Center(
                  child: Icon(
                    Icons.bubble_chart_outlined,
                    size: 72,
                    color: Color(0xFF67BBB5),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );

  Widget _bubble(int id) => Semantics(
    label: 'Pop ${widget.targets[id].word} bubble',
    button: true,
    excludeSemantics: true,
    onTap: () => _pop(id),
    child: Material(
      color: widget.bubbleColor,
      shape: const CircleBorder(),
      child: InkWell(
        key: ValueKey('repeat-bubble-$id'),
        customBorder: const CircleBorder(),
        onTap: () => _pop(id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF9BD2DE), width: 2),
          ),
          child: TemplatePicture(widget.targets[id].pictureAsset),
        ),
      ),
    ),
  );
}

class _PopRings extends CustomPainter {
  const _PopRings(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()
      ..color = const Color(0xFFBCEAF1).withValues(alpha: 1 - progress);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final radius = size.shortestSide * (.35 + .25 * progress);
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        5 * (1 - progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PopRings oldDelegate) => progress != oldDelegate.progress;
}
