import 'package:flutter/material.dart';

class BeaverSpriteAnimation extends StatefulWidget {
  final String assetPath;
  final int frameCount;
  final int fps;
  final bool loop;
  final double width;
  final double height;
  final VoidCallback? onComplete;

  const BeaverSpriteAnimation({
    super.key,
    required this.assetPath,
    required this.frameCount,
    required this.fps,
    required this.loop,
    required this.width,
    required this.height,
    this.onComplete,
  });

  @override
  State<BeaverSpriteAnimation> createState() => _BeaverSpriteAnimationState();
}

class _BeaverSpriteAnimationState extends State<BeaverSpriteAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _didComplete = false;

  @override
  void initState() {
    super.initState();
    _controller = _createController();
    _start();
  }

  @override
  void didUpdateWidget(covariant BeaverSpriteAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.assetPath != widget.assetPath ||
        oldWidget.frameCount != widget.frameCount ||
        oldWidget.fps != widget.fps ||
        oldWidget.loop != widget.loop) {
      _controller.dispose();
      _didComplete = false;
      _controller = _createController();
      _start();
    }
  }

  AnimationController _createController() {
    final safeFps = widget.fps <= 0 ? 1 : widget.fps;
    final safeFrameCount = widget.frameCount <= 0 ? 1 : widget.frameCount;
    final duration = Duration(
      milliseconds: ((safeFrameCount / safeFps) * 1000).round(),
    );

    return AnimationController(
      vsync: this,
      duration: duration,
    )..addStatusListener((status) {
      if (widget.loop || status != AnimationStatus.completed || _didComplete) {
        return;
      }

      _didComplete = true;
      widget.onComplete?.call();
    });
  }

  void _start() {
    if (widget.loop) {
      _controller.repeat();
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frameCount = widget.frameCount <= 0 ? 1 : widget.frameCount;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final frame = _controller.isCompleted
            ? frameCount - 1
            : (_controller.value * frameCount).floor().clamp(0, frameCount - 1);
        final alignmentX = frameCount == 1
            ? 0.0
            : -1.0 + (2.0 * frame / (frameCount - 1));

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: ClipRect(
            child: OverflowBox(
              minWidth: widget.width * frameCount,
              maxWidth: widget.width * frameCount,
              minHeight: widget.height,
              maxHeight: widget.height,
              alignment: Alignment(alignmentX, 0),
              child: Image.asset(
                widget.assetPath,
                width: widget.width * frameCount,
                height: widget.height,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
