import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../controllers/home_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/profile_model.dart';
import '../../screens/gameplay/gameplay_screen.dart';
import '../../widgets/profile_avatar.dart';
import 'learning_report_page.dart';
import 'user_select_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    final homeController = context.read<HomeController>();
    homeController.ensureCurrentUserProfileAssets().catchError((error) {
      debugPrint('Profile asset backfill failed: $error');
    });
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeController = context.read<HomeController>();

    return Scaffold(
      body: StreamBuilder<ProfileModel?>(
        stream: homeController.currentUserProfileStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _OceanShell(
              animation: _motionController,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }

          final profile = snapshot.data;

          if (profile == null) {
            return _OceanShell(
              animation: _motionController,
              child: const Center(child: _EmptyProfileMessage()),
            );
          }

          return _OceanHomeView(profile: profile, animation: _motionController);
        },
      ),
    );
  }
}

class _OceanHomeView extends StatefulWidget {
  final ProfileModel profile;
  final Animation<double> animation;

  const _OceanHomeView({required this.profile, required this.animation});

  @override
  State<_OceanHomeView> createState() => _OceanHomeViewState();
}

class _OceanHomeViewState extends State<_OceanHomeView> {
  static const int _islandOneTotalLevels = 4;

  late final ScrollController _scrollController;
  final Set<int> _completedIslandOneLevels = {};
  ProfileModel? _selectedProfileOverride;
  int _currentIsland = 0;
  int _unlockedIslandOneLevels = 1;

  ProfileModel get _activeProfile => _selectedProfileOverride ?? widget.profile;

  List<_QuestProgress> get _quests {
    final completedCount = _completedIslandOneLevels.length;

    return [
      _QuestProgress(
        title: 'Activity 1: The Sound Pop!',
        levelsDone: completedCount,
        totalLevels: _islandOneTotalLevels,
      ),
      const _QuestProgress(
        title: 'Activity 2: Word Splash!',
        levelsDone: 0,
        totalLevels: 4,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
  }

  @override
  void didUpdateWidget(covariant _OceanHomeView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.profile.profileId != widget.profile.profileId) {
      _selectedProfileOverride = null;
      _resetLocalProgress();
      return;
    }

    if (_selectedProfileOverride?.profileId == widget.profile.profileId) {
      _selectedProfileOverride = null;
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final progress = maxScroll <= 0
        ? 0.0
        : _scrollController.offset / maxScroll;
    final nextIsland = progress >= 0.44 ? 1 : 0;

    if (nextIsland != _currentIsland) {
      setState(() {
        _currentIsland = nextIsland;
      });
    }
  }

  void _resetLocalProgress() {
    _completedIslandOneLevels.clear();
    _currentIsland = 0;
    _unlockedIslandOneLevels = 1;
  }

  Future<void> _openUserSelect(List<ProfileModel> profiles) async {
    final activeProfile = _activeProfile;
    final selectedProfile = await Navigator.of(context).push<ProfileModel>(
      MaterialPageRoute(
        builder: (_) => UserSelectPage(
          activeProfile: activeProfile,
          profiles: profiles,
        ),
      ),
    );

    if (!mounted || selectedProfile == null) return;

    setState(() {
      if (selectedProfile.profileId != _activeProfile.profileId) {
        _resetLocalProgress();
      }
      _selectedProfileOverride = selectedProfile;
    });
  }

  LearningReportMetrics get _reportMetrics {
    final completedLevels = _completedIslandOneLevels.length;

    return LearningReportMetrics(
      activities: _quests.length,
      minutes: completedLevels == 0 ? 10 : completedLevels * 5,
      words: completedLevels == 0 ? 4 : completedLevels,
      levels: completedLevels == 0 ? 6 : completedLevels,
    );
  }

  Future<void> _openLearningReport() {
    final activeProfile = _activeProfile;

    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LearningReportPage(
          profile: activeProfile,
          thisWeek: _reportMetrics,
          overall: _reportMetrics,
        ),
      ),
    );
  }

  Future<void> _openGameplayLevel(int levelIndex) async {
    final activeProfile = _activeProfile;
    final result = await Navigator.of(context).push<GameplayLevelResult>(
      MaterialPageRoute(
        builder: (_) => GameplayScreen(
          childProfileId: activeProfile.profileId,
          childName: activeProfile.childName,
          childAge: activeProfile.age,
          levelIndex: levelIndex,
        ),
      ),
    );

    if (!mounted || result == null || !result.correct) return;

    setState(() {
      _completedIslandOneLevels.add(result.levelIndex);
      _unlockedIslandOneLevels = math.min(
        _islandOneTotalLevels,
        math.max(_unlockedIslandOneLevels, result.levelIndex + 2),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final activeProfile = _activeProfile;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final titleTop = padding.top + (compact ? 76.0 : 26.0);
        final currentQuest = _quests[_currentIsland];

        return Stack(
          children: [
            _ScrollableOceanMap(
              animation: widget.animation,
              scrollController: _scrollController,
              unlockedIslandOneLevels: _unlockedIslandOneLevels,
              completedIslandOneLevels: _completedIslandOneLevels,
              onStartGameplay: _openGameplayLevel,
            ),
            Positioned(
              top: padding.top + (compact ? 18 : 30),
              left: compact ? 18 : 40,
              child: StreamBuilder<List<ProfileModel>>(
                stream: context.read<HomeController>().childProfilesStream(),
                builder: (context, snapshot) {
                  final profiles = snapshot.data?.isNotEmpty == true
                      ? snapshot.data!
                      : [activeProfile];
                  return _ProfileChip(
                    profile: activeProfile,
                    onTap: () => _openUserSelect(profiles),
                  );
                },
              ),
            ),
            Positioned(
              top: titleTop,
              left: compact ? 92 : 0,
              right: compact ? 92 : 0,
              child: _LessonTitle(title: currentQuest.title),
            ),
            Positioned(
              top: padding.top + (compact ? 18 : 30),
              right: compact ? 18 : 58,
              child: _ProgressBadge(
                quest: currentQuest,
                onTap: _openLearningReport,
              ),
            ),
            Positioned(
              left: compact ? 18 : 40,
              bottom: padding.bottom + 24,
              child: _MapIconButton(
                assetPath: 'assets/icons/learning_report_button.svg',
                label: 'Learning report',
                width: 50,
                height: 50,
                onTap: _openLearningReport,
              ),
            ),
            Positioned(
              right: compact ? 18 : 58,
              bottom: padding.bottom + 24,
              child: const _MapIconButton(
                assetPath: 'assets/icons/customize_button.svg',
                label: 'Customize',
                width: 63,
                height: 73,
              ),
            ),
          ],
        );
      },
    );
  }
}

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

class _ProfileChip extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onTap;

  const _ProfileChip({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 124,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
            child: Row(
              children: [
                ProfileAvatar(
                  assetPath: profile.profileAssetPath,
                  fallbackSeed: profile.profileId,
                  size: 40,
                  borderWidth: 1.5,
                  borderRadius: 20,
                  borderColor: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.childName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF4B4B4B),
                          fontFamily: AppFonts.fredoka,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                          letterSpacing: 0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFC400),
                            size: 13,
                          ),
                          SizedBox(width: 1),
                          Text(
                            '500',
                            style: TextStyle(
                              color: Color(0xFFFFC400),
                              fontFamily: AppFonts.fredokaOne,
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              height: 1,
                              letterSpacing: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _QuestProgress {
  final String title;
  final int levelsDone;
  final int totalLevels;

  const _QuestProgress({
    required this.title,
    required this.levelsDone,
    required this.totalLevels,
  });
}

class _ProgressBadge extends StatelessWidget {
  final _QuestProgress quest;
  final VoidCallback onTap;

  const _ProgressBadge({
    required this.quest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentLevel = math.min(
      quest.totalLevels,
      math.max(1, quest.levelsDone + 1),
    );

    return Semantics(
      label:
          '${quest.title} progress $currentLevel of ${quest.totalLevels} levels',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 63,
          height: 73,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'Progress',
                maxLines: 1,
                style: TextStyle(
                  color: AppColors.primary,
                  fontFamily: AppFonts.fredokaOne,
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: Container(
                  width: 43,
                  height: 43,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$currentLevel/${quest.totalLevels}\nLevels',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: AppFonts.fredokaOne,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w400,
                      height: 0.95,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
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
    final lockedFilter = locked
        ? const ColorFilter.mode(Color(0xFF161616), BlendMode.srcIn)
        : null;

    return Positioned(
      left: left,
      top: top - size * 0.12,
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final wave = math.sin(
            (animation.value * math.pi * 14) + left / 140,
          );
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
                SvgPicture.asset(
                  assetPath,
                  width: visualSize,
                  height: visualSize,
                  fit: BoxFit.contain,
                  colorFilter: lockedFilter,
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

class _EmptyProfileMessage extends StatelessWidget {
  const _EmptyProfileMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'No user profile found.',
        style: TextStyle(
          color: AppColors.textGray,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
