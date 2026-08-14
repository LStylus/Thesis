part of 'home_page.dart';

class _SkyIslandShell extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _SkyIslandShell({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _FloatingIslandMap(animation: animation),
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

class _FloatingIslandMap extends StatelessWidget {
  final Animation<double> animation;
  final ScrollController? scrollController;
  final int unlockedIslandOneLevels;
  final Set<int> completedIslandOneLevels;
  final ValueChanged<int>? onStartGameplay;

  const _FloatingIslandMap({
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
        const sourceWidth = 917.0;
        const sourceHeight = 412.0;
        final viewportHeight = constraints.maxHeight;
        final scale = math.max(
          constraints.maxWidth / sourceWidth,
          viewportHeight / sourceHeight,
        );
        final mapWidth = sourceWidth * scale;
        final mapHeight = sourceHeight * scale;
        final sx = mapWidth / sourceWidth;
        final sy = mapHeight / sourceHeight;

        double x(double value) => value * sx;
        double y(double value) => value * sy;
        double s(double value) => value * sx;
        bool isIslandOneUnlocked(int levelIndex) {
          return levelIndex < unlockedIslandOneLevels;
        }

        return ClipRect(
          child: Stack(
            children: [
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF7DDAED), Color(0xFF6CA5B9)],
                    ),
                  ),
                ),
              ),
              Align(
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
                              child: SvgPicture.asset(
                                AppAssets.homeMapBackground,
                                fit: BoxFit.fill,
                              ),
                            ),
                            _LessonMapNode(
                              animation: animation,
                              label: 'Level 1',
                              left: x(119),
                              top: y(121),
                              size: s(58),
                              showFlag: true,
                              unlocked: isIslandOneUnlocked(0),
                              locked: !isIslandOneUnlocked(0),
                              completed: completedIslandOneLevels.contains(0),
                              onTap: isIslandOneUnlocked(0)
                                  ? () => onStartGameplay?.call(0)
                                  : null,
                            ),
                            _LessonMapNode(
                              animation: animation,
                              label: 'Level 2',
                              left: x(203),
                              top: y(119),
                              size: s(58),
                              unlocked: isIslandOneUnlocked(1),
                              locked: !isIslandOneUnlocked(1),
                              completed: completedIslandOneLevels.contains(1),
                              onTap: isIslandOneUnlocked(1)
                                  ? () => onStartGameplay?.call(1)
                                  : null,
                            ),
                            _LessonMapNode(
                              animation: animation,
                              label: 'Level 3',
                              left: x(270),
                              top: y(119),
                              size: s(58),
                              unlocked: isIslandOneUnlocked(2),
                              locked: !isIslandOneUnlocked(2),
                              completed: completedIslandOneLevels.contains(2),
                              onTap: isIslandOneUnlocked(2)
                                  ? () => onStartGameplay?.call(2)
                                  : null,
                            ),
                            _LessonMapNode(
                              animation: animation,
                              label: 'Level 4',
                              left: x(484),
                              top: y(116),
                              size: s(58),
                              unlocked: isIslandOneUnlocked(3),
                              locked: !isIslandOneUnlocked(3),
                              completed: completedIslandOneLevels.contains(3),
                              onTap: isIslandOneUnlocked(3)
                                  ? () => onStartGameplay?.call(3)
                                  : null,
                            ),
                            _LessonMapNode(
                              animation: animation,
                              label: 'Activity 2 locked',
                              left: x(672),
                              top: y(218),
                              size: s(58),
                              locked: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(child: _PassingCloudLayer(animation: animation)),
            ],
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

class _LessonMapNode extends StatelessWidget {
  final Animation<double> animation;
  final String label;
  final double left;
  final double top;
  final double size;
  final bool showFlag;
  final bool unlocked;
  final bool locked;
  final bool completed;
  final VoidCallback? onTap;

  const _LessonMapNode({
    required this.animation,
    required this.label,
    required this.left,
    required this.top,
    required this.size,
    this.showFlag = false,
    this.unlocked = false,
    this.locked = false,
    this.completed = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
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
        child: Semantics(
          label: label,
          button: !locked,
          enabled: !locked,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: locked ? null : onTap,
              borderRadius: BorderRadius.circular(size / 2),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (unlocked && !locked && !showFlag)
                    Container(
                      width: size * 0.82,
                      height: size * 0.82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.82),
                          width: math.max(1.5, size * 0.035),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFEAF98E,
                            ).withValues(alpha: 0.7),
                            blurRadius: size * 0.22,
                            spreadRadius: size * 0.03,
                          ),
                        ],
                      ),
                    ),
                  if (showFlag)
                    Transform.translate(
                      offset: Offset(0, -size * 0.16),
                      child: SvgPicture.asset(
                        AppAssets.homeMapFlag,
                        width: size * 0.76,
                        height: size * 0.76,
                        fit: BoxFit.contain,
                      ),
                    ),
                  if (locked)
                    SvgPicture.asset(
                      'assets/props/lock.svg',
                      width: size * 0.72,
                      height: size * 0.72,
                      fit: BoxFit.contain,
                    ),
                  if (completed)
                    Positioned(
                      right: size * 0.02,
                      bottom: size * 0.04,
                      child: Container(
                        width: size * 0.3,
                        height: size * 0.3,
                        decoration: BoxDecoration(
                          color: const Color(0xFF18A85A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: size * 0.21,
                        ),
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
}

class _PassingCloudLayer extends StatelessWidget {
  final Animation<double> animation;

  const _PassingCloudLayer({required this.animation});

  static const List<_PassingCloudSpec> _clouds = [
    _PassingCloudSpec(
      phase: 0.02,
      verticalPosition: 0.05,
      width: 76,
      opacity: 0.82,
      cycles: 1,
      bob: 4,
    ),
    _PassingCloudSpec(
      phase: 0.38,
      verticalPosition: 0.07,
      width: 104,
      opacity: 0.64,
      cycles: 1,
      bob: 7,
    ),
    _PassingCloudSpec(
      phase: 0.14,
      verticalPosition: 0.28,
      width: 58,
      opacity: 0.5,
      cycles: 2,
      bob: 3,
    ),
    _PassingCloudSpec(
      phase: 0.72,
      verticalPosition: 0.03,
      width: 88,
      opacity: 0.74,
      cycles: 1,
      bob: 5,
    ),
    _PassingCloudSpec(
      phase: 0.56,
      verticalPosition: 0.62,
      width: 66,
      opacity: 0.46,
      cycles: 1,
      bob: 4,
    ),
    _PassingCloudSpec(
      phase: 0.84,
      verticalPosition: 0.8,
      width: 90,
      opacity: 0.4,
      cycles: 1,
      bob: 6,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final scale = (constraints.maxHeight / 412).clamp(0.72, 1.5);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final cloud in _clouds)
                      _buildCloud(cloud, constraints.biggest, scale.toDouble()),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCloud(_PassingCloudSpec cloud, Size viewport, double scale) {
    final width = cloud.width * scale;
    final height = width * (46 / 73);
    final progress = (animation.value * cloud.cycles + cloud.phase) % 1.0;
    final travelDistance = viewport.width + width * 2;
    final left = viewport.width + width - (progress * travelDistance);
    final top =
        viewport.height * cloud.verticalPosition +
        math.sin(progress * math.pi * 2) * cloud.bob;

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: Opacity(
        opacity: cloud.opacity,
        child: SvgPicture.asset(AppAssets.passingCloud, fit: BoxFit.contain),
      ),
    );
  }
}

class _PassingCloudSpec {
  final double phase;
  final double verticalPosition;
  final double width;
  final double opacity;
  final int cycles;
  final double bob;

  const _PassingCloudSpec({
    required this.phase,
    required this.verticalPosition,
    required this.width,
    required this.opacity,
    required this.cycles,
    required this.bob,
  });
}
