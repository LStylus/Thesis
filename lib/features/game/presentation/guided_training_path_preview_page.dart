import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'template_preview_widgets.dart';

enum PathObstacle { rocks, steppingStones, gate }

class GuidedPathStop {
  const GuidedPathStop(this.word, this.pictureAsset, this.obstacle);
  final String word;
  final String pictureAsset;
  final PathObstacle obstacle;
}

enum _PathPhase { model, speak, crossing, arrived }

/// Storyboard preview only. Crossing is explicitly simulated, never speech credit.
class GuidedTrainingPathPreviewPage extends StatefulWidget {
  const GuidedTrainingPathPreviewPage({
    super.key,
    this.backgroundColor = Colors.white,
    this.backgroundImage,
    this.characterAsset = 'assets/characters/path_explorer_placeholder.svg',
    this.stops = const [
      GuidedPathStop('Ball', 'assets/game/words/ball.svg', PathObstacle.rocks),
      GuidedPathStop(
        'Key',
        'assets/game/words/key.svg',
        PathObstacle.steppingStones,
      ),
      GuidedPathStop('Dog', 'assets/game/words/dog.svg', PathObstacle.gate),
    ],
  });
  static const routeName = '/dev/guided-training-path';
  final Color backgroundColor;
  final ImageProvider? backgroundImage;
  final String characterAsset;
  final List<GuidedPathStop> stops;
  @override
  State<GuidedTrainingPathPreviewPage> createState() => _GuidedPathState();
}

class _GuidedPathState extends State<GuidedTrainingPathPreviewPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _crossing;
  int _scene = 0;
  _PathPhase _phase = _PathPhase.model;
  bool _foreground = true, _paused = false;
  bool get _reduced => MediaQuery.disableAnimationsOf(context);
  GuidedPathStop get _stop => widget.stops[_scene];
  bool get _last => _scene == widget.stops.length - 1;

  @override
  void initState() {
    super.initState();
    assert(widget.stops.length == 3);
    _crossing =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 2400),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() {
              _phase = _PathPhase.arrived;
              _paused = false;
            });
          }
        });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduced && _phase == _PathPhase.crossing && _foreground && !_paused) {
      _crossing.value = 1;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && _phase == _PathPhase.crossing) {
      _crossing.stop();
      setState(() => _paused = true);
    }
  }

  void _previewCrossing() {
    if (!_foreground || _phase != _PathPhase.speak) return;
    setState(() {
      _phase = _PathPhase.crossing;
      _paused = false;
    });
    if (_reduced) {
      _crossing.value = 1;
    } else {
      _crossing.forward(from: 0);
    }
  }

  void _pauseOrResume() {
    if (!_foreground || _phase != _PathPhase.crossing) return;
    setState(() => _paused = !_paused);
    if (_paused) {
      _crossing.stop();
    } else if (_reduced) {
      _crossing.value = 1;
    } else {
      _crossing.forward();
    }
  }

  void _reset({bool nextScene = false}) {
    if (nextScene && (_phase != _PathPhase.arrived || _last)) return;
    _crossing.reset();
    setState(() {
      _scene = nextScene ? _scene + 1 : 0;
      _phase = _PathPhase.model;
      _paused = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _crossing.dispose();
    super.dispose();
  }

  String get _caption => switch (_phase) {
    _PathPhase.model => 'This is a ${_stop.word.toLowerCase()}.',
    _PathPhase.speak => 'Your turn: say ${_stop.word.toLowerCase()}.',
    _PathPhase.crossing =>
      _paused
          ? 'Preview paused. Continue when you are ready.'
          : 'Watch the crossing animation!',
    _PathPhase.arrived =>
      _last
          ? 'Path animation preview finished!'
          : 'Across safely! See the next scene.',
  };

  @override
  Widget build(BuildContext context) => TemplateSurface(
    backgroundColor: widget.backgroundColor,
    backgroundImage: widget.backgroundImage,
    builder: (context, wide, viewport) {
      final compact = wide && viewport.height < 350;
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Scene ${_scene + 1} of 3 · Animation preview',
                  key: const ValueKey('path-scene'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF677D86),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Restart path preview',
                onPressed: () => _reset(),
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.replay, size: 20),
              ),
            ],
          ),
          TemplateCaption(_caption),
          const SizedBox(height: 8),
          if (wide)
            Row(
              children: [
                _pictureCard(compact ? 72 : 116),
                const SizedBox(width: 12),
                Expanded(child: _pathScene(compact ? 104 : 210)),
              ],
            )
          else ...[
            _pictureCard(116),
            const SizedBox(height: 12),
            _pathScene(230),
          ],
          const SizedBox(height: 4),
          _controls(),
          const SizedBox(height: 4),
          const Text(
            'Template only · No recording, speech checking or saved progress.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF677D86)),
          ),
        ],
      );
    },
  );

  Widget _pictureCard(double size) => Container(
    key: const ValueKey('path-word-picture'),
    width: size,
    height: size,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F8FA),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFD4E6EB)),
    ),
    child: Semantics(
      label: _stop.word,
      image: true,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: _reduced ? 0 : 350),
        child: TemplatePicture(_stop.pictureAsset, key: ValueKey(_scene)),
      ),
    ),
  );

  Widget _controls() => switch (_phase) {
    _PathPhase.model => FilledButton.icon(
      onPressed: () => setState(() => _phase = _PathPhase.speak),
      icon: const Icon(Icons.arrow_forward, size: 18),
      label: const Text('Your turn'),
    ),
    _PathPhase.speak => Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        FilledButton.icon(
          onPressed: _previewCrossing,
          icon: const Icon(Icons.movie_outlined, size: 18),
          label: const Text('Preview crossing animation'),
        ),
        TextButton(
          onPressed: () => setState(() => _phase = _PathPhase.model),
          child: const Text('Show word caption'),
        ),
      ],
    ),
    _PathPhase.crossing => OutlinedButton.icon(
      onPressed: _pauseOrResume,
      icon: Icon(_paused ? Icons.play_arrow : Icons.pause, size: 18),
      label: Text(_paused ? 'Resume preview' : 'Pause preview'),
    ),
    _PathPhase.arrived => FilledButton.icon(
      onPressed: () => _reset(nextScene: !_last),
      icon: Icon(_last ? Icons.replay : Icons.arrow_forward, size: 18),
      label: Text(_last ? 'Replay path preview' : 'Next scene'),
    ),
  };

  Widget _pathScene(double height) => SizedBox(
    key: const ValueKey('path-field'),
    height: height,
    width: double.infinity,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: const Color(0xFFF8FBF8),
        child: LayoutBuilder(
          builder: (context, bounds) {
            final actor = math.min(90.0, bounds.maxHeight * 0.5);
            final floor = bounds.maxHeight * 0.78;
            return AnimatedBuilder(
              animation: _crossing,
              builder: (context, child) {
                final t = _crossing.value;
                final walking =
                    _phase == _PathPhase.crossing && !_paused && !_reduced;
                final local = ((t - 0.28) / 0.44).clamp(0.0, 1.0);
                final hop = switch (_stop.obstacle) {
                  PathObstacle.gate => 0.0,
                  PathObstacle.rocks =>
                    math.sin(local * math.pi) * bounds.maxHeight * 0.23,
                  PathObstacle.steppingStones =>
                    math.sin(local * math.pi * 3).abs() *
                        bounds.maxHeight *
                        0.15,
                };
                final bob = walking
                    ? math.sin(t * math.pi * 16).abs() * 3
                    : 0.0;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PathSceneryPainter(_stop.obstacle, t),
                      ),
                    ),
                    Positioned(
                      left: bounds.maxWidth * 0.85,
                      bottom: bounds.maxHeight * 0.22,
                      child: const Icon(
                        Icons.flag_rounded,
                        color: Color(0xFF5CAC92),
                        size: 27,
                      ),
                    ),
                    Positioned(
                      left:
                          (bounds.maxWidth - actor) *
                          (0.06 + 0.78 * Curves.easeInOut.transform(t)),
                      top: floor - actor - hop - bob,
                      width: actor,
                      height: actor,
                      child: Transform.rotate(
                        angle: walking ? math.sin(t * math.pi * 16) * 0.035 : 0,
                        child: child,
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 8,
                      child: Text(
                        switch (_stop.obstacle) {
                          PathObstacle.rocks => 'Rock hop',
                          PathObstacle.steppingStones => 'Stepping stones',
                          PathObstacle.gate => 'Garden gate',
                        },
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF81958B),
                        ),
                      ),
                    ),
                  ],
                );
              },
              child: Semantics(
                label: 'Explorer character',
                image: true,
                child: KeyedSubtree(
                  key: const ValueKey('path-character'),
                  child: TemplatePicture(widget.characterAsset),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

/// Code-drawn scenery placeholders can later be replaced with finished layers.
class _PathSceneryPainter extends CustomPainter {
  const _PathSceneryPainter(this.obstacle, this.progress);
  final PathObstacle obstacle;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final floor = size.height * 0.78;
    final paint = Paint()..color = const Color(0xFFE2EBDD);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, floor - 4, size.width - 20, 18),
        const Radius.circular(9),
      ),
      paint,
    );
    paint
      ..color = const Color(0xFFBDCBB5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = 22.0; x < size.width - 20; x += 18) {
      canvas.drawLine(Offset(x, floor + 5), Offset(x + 6, floor + 5), paint);
    }
    final center = size.width * 0.53;
    switch (obstacle) {
      case PathObstacle.rocks:
        for (var i = 0; i < 3; i++) {
          final h = i == 1 ? 26.0 : 17.0;
          paint.color = i == 1
              ? const Color(0xFF9DAAB0)
              : const Color(0xFFB6C1C5);
          canvas.drawOval(
            Rect.fromLTWH(center - 35 + i * 20, floor - h, 30, h + 5),
            paint,
          );
        }
      case PathObstacle.steppingStones:
        paint.color = const Color(0xFFBDE5EE);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(center - 48, floor - 8, 96, 27),
            const Radius.circular(14),
          ),
          paint,
        );
        for (var i = 0; i < 3; i++) {
          paint.color = const Color(0xFF94B2AC);
          canvas.drawOval(
            Rect.fromLTWH(center - 40 + i * 28, floor - 10, 22, 12),
            paint,
          );
        }
      case PathObstacle.gate:
        paint.color = const Color(0xFFB9C9A4);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(center - 28, floor - 39, 8, 43),
            const Radius.circular(3),
          ),
          paint,
        );
        final open = Curves.easeInOut.transform(
          (progress / 0.3).clamp(0.0, 1.0),
        );
        canvas.save();
        canvas.translate(center - 24, floor - 32);
        canvas.rotate(-open * math.pi * 0.47);
        paint.color = const Color(0xFF98B68C);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0, 0, 55, 7),
            const Radius.circular(3),
          ),
          paint,
        );
        canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PathSceneryPainter oldDelegate) =>
      oldDelegate.obstacle != obstacle || oldDelegate.progress != progress;
}
