import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Local preview progress only; no profile, microphone or score writes.
class FallingSoundBubblesPreviewPage extends StatefulWidget {
  const FallingSoundBubblesPreviewPage({
    super.key,
    this.backgroundColor = Colors.white,
    this.backgroundImage,
    this.bubbleShellImage,
    this.firstImage,
    this.secondImage,
    this.thirdImage,
    this.randomSeed,
  });
  static const routeName = '/dev/falling-sound-bubbles';
  final Color backgroundColor;
  final ImageProvider? backgroundImage;
  final ImageProvider? bubbleShellImage;
  final ImageProvider? firstImage;
  final ImageProvider? secondImage;
  final ImageProvider? thirdImage;

  /// Optional deterministic motion for preview tests.
  final int? randomSeed;

  @override
  State<FallingSoundBubblesPreviewPage> createState() =>
      _FallingSoundBubblesState();
}

class _FallingSoundBubblesState extends State<FallingSoundBubblesPreviewPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _words = ['Ball', 'Key', 'Dog'];
  static const _ink = Color(0xFF244653);
  late final math.Random _random = math.Random(widget.randomSeed);
  late final Ticker _fall = createTicker(_tick);
  final _motion = ValueNotifier<int>(0);
  final _flights = <_BubbleFlight>[];
  Duration _lastTick = Duration.zero;
  Timer? _captionTimer;
  static const _captionDuration = Duration(seconds: 3);
  final _viewed = <int>{};
  int? _active;
  int _attempt = 0;
  bool _interrupted = false,
      _paused = false,
      _foreground = true,
      _reducedMotion = false;

  @override
  void initState() {
    super.initState();
    _resetFlights();
    WidgetsBinding.instance.addObserver(this);
  }

  _BubbleFlight _newFlight() => _BubbleFlight(
    x: 0.03 + _random.nextDouble() * 0.94,
    duration: 6 + _random.nextDouble() * 5,
    elapsed: -(0.3 + _random.nextDouble() * 1.8),
  );

  void _resetFlights() {
    _flights.clear();
    // Randomize the word order as well as the height. Spacing is only for the
    // opening arrangement; subsequent flights can start anywhere across the field.
    final positions = [0.08, 0.5, 0.92]..shuffle(_random);
    final heights = [0.25, 0.45, 0.65]..shuffle(_random);
    for (var i = 0; i < 3; i++) {
      final flight = _newFlight();
      flight.x = positions[i] + (_random.nextDouble() - 0.5) * 0.1;
      flight.elapsed =
          flight.duration * (heights[i] + (_random.nextDouble() - 0.5) * 0.08);
      _flights.add(flight);
    }
  }

  void _tick(Duration elapsed) {
    final delta = (elapsed - _lastTick).inMicroseconds / 1000000;
    _lastTick = elapsed;
    for (var i = 0; i < _flights.length; i++) {
      if (_viewed.contains(i)) continue;
      var flight = _flights[i];
      flight.elapsed += delta;
      // Reroll only after leaving the bottom, never during a visible fall.
      while (flight.elapsed >= flight.duration) {
        final remainder = flight.elapsed - flight.duration;
        flight = _newFlight()..elapsed += remainder;
        _flights[i] = flight;
      }
    }
    _motion.value++;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reducedMotion = MediaQuery.disableAnimationsOf(context);
    _syncMotion();
  }

  void _syncMotion() {
    if (_active == null &&
        !_paused &&
        _foreground &&
        !_reducedMotion &&
        _viewed.length < 3) {
      if (!_fall.isActive) {
        _lastTick = Duration.zero;
        _fall.start();
      }
    } else {
      _fall.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground && _active != null) {
      _attempt++;
      _captionTimer?.cancel();
      setState(() => _interrupted = true);
    }
    _syncMotion();
  }

  void _pop(int index) {
    if (_active != null || _viewed.contains(index) || !_foreground) return;
    setState(() {
      _active = index;
      _interrupted = false;
    });
    _syncMotion();
    _showCaption();
  }

  void _showCaption() {
    if (!_foreground) return;
    final index = _active;
    if (index == null) return;
    final attempt = ++_attempt;
    _captionTimer?.cancel();
    setState(() => _interrupted = false);
    _captionTimer = Timer(_captionDuration, () {
      if (!mounted || !_foreground || attempt != _attempt || _active != index) {
        return;
      }
      setState(() {
        _viewed.add(index);
        _active = null;
      });
      _syncMotion();
    });
  }

  void _returnBubble() {
    _attempt++;
    _captionTimer?.cancel();
    setState(() {
      _active = null;
      _interrupted = false;
    });
    _syncMotion();
  }

  @override
  void dispose() {
    _attempt++;
    WidgetsBinding.instance.removeObserver(this);
    _fall.dispose();
    _motion.dispose();
    _captionTimer?.cancel();
    super.dispose();
  }

  Widget _picture(int index) {
    final image = [
      widget.firstImage,
      widget.secondImage,
      widget.thirdImage,
    ][index];
    if (image != null) {
      return Image(
        image: image,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Center(child: Text(_words[index])),
      );
    }
    return SvgPicture.asset(
      'assets/game/words/${_words[index].toLowerCase()}.svg',
      fit: BoxFit.contain,
      semanticsLabel: _words[index],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: widget.backgroundColor,
    body: Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              image: widget.backgroundImage == null
                  ? null
                  : DecorationImage(
                      image: widget.backgroundImage!,
                      fit: BoxFit.cover,
                    ),
            ),
            child: SafeArea(
              child: ExcludeSemantics(
                excluding: _active != null,
                child: IgnorePointer(
                  ignoring: _active != null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Watch the sound bubbles',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  color: _ink,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: _paused
                                  ? 'Resume bubbles'
                                  : 'Pause bubbles',
                              onPressed: () {
                                setState(() => _paused = !_paused);
                                _syncMotion();
                              },
                              icon: Icon(
                                _paused ? Icons.play_arrow : Icons.pause,
                              ),
                            ),
                          ],
                        ),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Tap a bubble to see its caption. Missed bubbles come back.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF677D86),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, field) {
                              final size = math.min(
                                180.0,
                                math.min(
                                  field.maxWidth / 3.6,
                                  field.maxHeight * 0.55,
                                ),
                              );
                              return ClipRect(
                                child: AnimatedBuilder(
                                  animation: _motion,
                                  builder: (context, _) => Stack(
                                    key: const ValueKey('bubble-field'),
                                    fit: StackFit.expand,
                                    children: [
                                      for (var i = 0; i < 3; i++)
                                        if (!_viewed.contains(i) &&
                                            _active != i)
                                          Positioned(
                                            left:
                                                (field.maxWidth - size) *
                                                (_reducedMotion
                                                    ? (0.04 + i * 0.46)
                                                    : _flights[i].x),
                                            top: _reducedMotion
                                                ? (field.maxHeight - size) *
                                                      (0.15 + i * 0.25)
                                                : _flights[i].progress *
                                                          (field.maxHeight +
                                                              size) -
                                                      size,
                                            width: size,
                                            height: size,
                                            child: Semantics(
                                              label: 'Pop ${_words[i]} bubble',
                                              button: true,
                                              onTap: () => _pop(i),
                                              excludeSemantics: true,
                                              child: Container(
                                                key: ValueKey(
                                                  'sound-bubble-${i + 1}',
                                                ),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient:
                                                      const RadialGradient(
                                                        center: Alignment(
                                                          -0.3,
                                                          -0.4,
                                                        ),
                                                        radius: 0.9,
                                                        colors: [
                                                          Colors.white,
                                                          Color(0xFFD9F2F8),
                                                        ],
                                                      ),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFFA8DCE8,
                                                    ),
                                                    width: 2,
                                                  ),
                                                  image:
                                                      widget.bubbleShellImage ==
                                                          null
                                                      ? null
                                                      : DecorationImage(
                                                          image: widget
                                                              .bubbleShellImage!,
                                                          fit: BoxFit.contain,
                                                        ),
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    customBorder:
                                                        const CircleBorder(),
                                                    onTap: () => _pop(i),
                                                    child: Padding(
                                                      padding: EdgeInsets.all(
                                                        size * 0.2,
                                                      ),
                                                      child: _picture(i),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      if (_viewed.length == 3)
                                        Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.check_circle_outline,
                                                size: 44,
                                                color: Color(0xFF24988A),
                                              ),
                                              const Text(
                                                'All pictures viewed!',
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  color: _ink,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _viewed.clear();
                                                    _resetFlights();
                                                  });
                                                  _syncMotion();
                                                },
                                                child: const Text('Play again'),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_viewed.length} of 3 viewed',
                          key: const ValueKey('bubble-progress'),
                          style: const TextStyle(color: _ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_active != null) ...[
          const Positioned.fill(
            child: ModalBarrier(
              key: ValueKey('spotlight-backdrop'),
              color: Color(0xD9000000),
              dismissible: false,
            ),
          ),
          Positioned.fill(child: _spotlight(_active!)),
        ],
      ],
    ),
  );
  Widget _spotlight(int index) => SafeArea(
    child: LayoutBuilder(
      builder: (context, bounds) {
        final size = math.max(
          48.0,
          math.min(
            320.0,
            math.min(
              bounds.maxWidth * 0.65,
              bounds.maxHeight - (_interrupted ? 180 : 115),
            ),
          ),
        );
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  key: ValueKey('bubble-pop-$index'),
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: _reducedMotion ? 0 : 450),
                  builder: (context, value, child) => Transform.scale(
                    scale: 0.75 + 0.25 * Curves.easeOutBack.transform(value),
                    child: Container(
                      width: size,
                      height: size,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Color.lerp(
                            const Color(0xFFA8DCE8),
                            Colors.white,
                            value,
                          )!,
                          width: 2 + (1 - value) * 8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(
                              alpha: 0.25 * (1 - value),
                            ),
                            spreadRadius: value * 35,
                            blurRadius: 22,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                  child: _picture(index),
                ),
                const SizedBox(height: 12),
                Text(
                  'This is a ${_words[index].toLowerCase()}.',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _interrupted
                        ? 'Caption paused. Tap Show caption to continue.'
                        : 'Temporary caption · Voice-over coming later',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                if (_interrupted)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    children: [
                      TextButton(
                        onPressed: _showCaption,
                        child: const Text(
                          'Show caption',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: _returnBubble,
                        child: const Text(
                          'Return bubble',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _BubbleFlight {
  _BubbleFlight({
    required this.x,
    required this.duration,
    required this.elapsed,
  });

  double x;
  final double duration;
  double elapsed;

  double get progress => (elapsed / duration).clamp(0.0, 1.0);
}
