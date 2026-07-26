part of 'home_page.dart';

class _OceanShell extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _OceanShell({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _ScrollableOceanMap(animation: animation),
        Positioned.fill(
          child: ColoredBox(
            color: Colors.black.withValues(alpha: 0.18),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _ScrollableOceanMap extends StatelessWidget {
  final Animation<double> animation;
  final ScrollController? scrollController;
  final int unlockedIslandOneLevels;
  final Set<int> completedIslandOneLevels;
  final ValueChanged<int>? onStartGameplay;

  const _ScrollableOceanMap({
    required this.animation,
    this.scrollController,
    this.unlockedIslandOneLevels = 1,
    this.completedIslandOneLevels = const {},
    this.onStartGameplay,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const sourceWidth = 2173.0;
        const sourceHeight = 724.0;
        final viewportHeight = constraints.maxHeight;
        final mapHeight = math.max(1.0, viewportHeight * 1.40);
        final mapWidth = mapHeight * (sourceWidth / sourceHeight);
        final sx = mapWidth / sourceWidth;
        final sy = mapHeight / sourceHeight;

        double x(double value) => value * sx;
        double y(double value) => value * sy;
        double s(double value) => value * sx;
        bool isIslandOneUnlocked(int levelIndex) {
          return levelIndex < unlockedIslandOneLevels;
        }

        return SizedBox(
          height: viewportHeight,
          child: Align(
            alignment: Alignment.center,
            child: SingleChildScrollView(
              controller: scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: mapWidth,
                height: viewportHeight,
                child: Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: mapWidth,
                    height: mapHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            'assets/backgrounds/ocean_map.png',
                            fit: BoxFit.fill,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: animation,
                              builder: (context, _) {
                                return CustomPaint(
                                  painter: _BubblesPainter(animation.value),
                                );
                              },
                            ),
                          ),
                        ),
                        _LessonMapNode(
                          animation: animation,
                          left: x(250),
                          top: y(233),
                          size: s(65),
                          unlocked: isIslandOneUnlocked(0),
                          locked: !isIslandOneUnlocked(0),
                          completed: completedIslandOneLevels.contains(0),
                          onTap: isIslandOneUnlocked(0)
                              ? () => onStartGameplay?.call(0)
                              : null,
                        ),
                        _LessonMapNode(
                          animation: animation,
                          left: x(380),
                          top: y(163),
                          size: s(65),
                          unlocked: isIslandOneUnlocked(1),
                          locked: !isIslandOneUnlocked(1),
                          completed: completedIslandOneLevels.contains(1),
                          onTap: isIslandOneUnlocked(1)
                              ? () => onStartGameplay?.call(1)
                              : null,
                        ),
                        _LessonMapNode(
                          animation: animation,
                          left: x(548),
                          top: y(200),
                          size: s(65),
                          unlocked: isIslandOneUnlocked(2),
                          locked: !isIslandOneUnlocked(2),
                          completed: completedIslandOneLevels.contains(2),
                          onTap: isIslandOneUnlocked(2)
                              ? () => onStartGameplay?.call(2)
                              : null,
                        ),
                        _LessonMapNode(
                          animation: animation,
                          left: x(767),
                          top: y(215),
                          size: s(65),
                          kind: _LessonNodeKind.chest,
                          unlocked: isIslandOneUnlocked(3),
                          locked: !isIslandOneUnlocked(3),
                          completed: completedIslandOneLevels.contains(3),
                          onTap: isIslandOneUnlocked(3)
                              ? () => onStartGameplay?.call(3)
                              : null,
                        ),
                        _LessonMapNode(
                          animation: animation,
                          left: x(1323),
                          top: y(237),
                          size: s(65),
                          locked: true,
                        ),
                        _LessonMapNode(
                          animation: animation,
                          left: x(1464),
                          top: y(180),
                          size: s(65),
                          locked: true,
                        ),
                        _LessonMapNode(
                          animation: animation,
                          left: x(1618),
                          top: y(231),
                          size: s(65),
                          locked: true,
                        ),
                        _LessonMapNode(
                          animation: animation,
                          left: x(1835),
                          top: y(241),
                          size: s(65),
                          kind: _LessonNodeKind.chest,
                          locked: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LessonTitle extends StatelessWidget {
  final String title;

  const _LessonTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 248,
        height: 50,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primary,
              fontFamily: AppFonts.fredokaOne,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const _MapIconButton({
    required this.assetPath,
    required this.label,
    required this.width,
    required this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SvgPicture.asset(
          assetPath,
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

enum _LessonNodeKind { flag, chest }

class _LessonMapNode extends StatelessWidget {
  final Animation<double> animation;
  final double left;
  final double top;
  final double size;
  final _LessonNodeKind kind;
  final bool unlocked;
  final bool locked;
  final bool completed;
  final VoidCallback? onTap;

  const _LessonMapNode({
    required this.animation,
    required this.left,
    required this.top,
    required this.size,
    this.kind = _LessonNodeKind.flag,
    this.unlocked = false,
    this.locked = false,
    this.completed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = kind == _LessonNodeKind.chest
        ? 'assets/props/treasure.svg'
        : 'assets/props/flag.svg';
    final visualSize = kind == _LessonNodeKind.chest ? size * 0.86 : size;

    return Positioned(
      left: left,
      top: top - size * 0.12,
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final wave = math.sin((animation.value * math.pi * 14) + left / 140);
          final bounce = unlocked && !locked ? wave : 0.0;
          final pulse = unlocked && !locked ? 1 + (bounce * 0.035) : 1.0;

          return Transform.translate(
            offset: Offset(0, -4 * bounce),
            child: Transform.scale(scale: pulse, child: child),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: locked ? null : onTap,
            borderRadius: BorderRadius.circular(size * 0.18),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: locked ? 0.6 : 1,
                  child: SvgPicture.asset(
                    assetPath,
                    width: visualSize,
                    height: visualSize,
                    fit: BoxFit.contain,
                  ),
                ),
                if (completed)
                  Positioned(
                    right: size * 0.08,
                    bottom: size * 0.1,
                    child: Container(
                      width: size * 0.28,
                      height: size * 0.28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF18A85A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: size * 0.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BubblesPainter extends CustomPainter {
  final double progress;

  const _BubblesPainter(this.progress);

  static const List<_BubbleSpec> _bubbles = [
    _BubbleSpec(x: 0.06, phase: 0.02, radius: 15, drift: 18, speed: 0.72),
    _BubbleSpec(x: 0.16, phase: 0.28, radius: 9, drift: 10, speed: 0.86),
    _BubbleSpec(x: 0.27, phase: 0.12, radius: 18, drift: 22, speed: 0.62),
    _BubbleSpec(x: 0.38, phase: 0.48, radius: 11, drift: 16, speed: 0.78),
    _BubbleSpec(x: 0.52, phase: 0.2, radius: 14, drift: 20, speed: 0.68),
    _BubbleSpec(x: 0.63, phase: 0.7, radius: 8, drift: 12, speed: 0.92),
    _BubbleSpec(x: 0.74, phase: 0.36, radius: 17, drift: 24, speed: 0.64),
    _BubbleSpec(x: 0.86, phase: 0.58, radius: 10, drift: 16, speed: 0.84),
    _BubbleSpec(x: 0.95, phase: 0.16, radius: 13, drift: 18, speed: 0.74),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final fill = Paint()..style = PaintingStyle.fill;

    for (final bubble in _bubbles) {
      final t = (progress * bubble.speed + bubble.phase) % 1.0;
      final x =
          size.width * bubble.x +
          math.sin((t + bubble.phase) * math.pi * 2) * bubble.drift;
      final y = size.height * (1.06 - t * 1.22);
      final fade = math.sin(t * math.pi).clamp(0.0, 1.0);
      final radius = bubble.radius * (0.8 + t * 0.45);

      fill.color = Colors.white.withValues(alpha: 0.08 * fade);
      stroke.color = Colors.white.withValues(alpha: 0.32 * fade);
      canvas.drawCircle(Offset(x, y), radius, fill);
      canvas.drawCircle(Offset(x, y), radius, stroke);

      fill.color = Colors.white.withValues(alpha: 0.28 * fade);
      canvas.drawCircle(
        Offset(x - radius * 0.32, y - radius * 0.32),
        math.max(2.4, radius * 0.16),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BubblesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _BubbleSpec {
  final double x;
  final double phase;
  final double radius;
  final double drift;
  final double speed;

  const _BubbleSpec({
    required this.x,
    required this.phase,
    required this.radius,
    required this.drift,
    required this.speed,
  });
}
