import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../models/profile_model.dart';
import '../screening/screening_page.dart';

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
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  Future<void> _openScreening(ProfileModel profile) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScreeningPage(childAge: profile.age)),
    );
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

          return _OceanHomeView(
            profile: profile,
            animation: _motionController,
            onStartScreening: () => _openScreening(profile),
          );
        },
      ),
    );
  }
}

class _OceanHomeView extends StatefulWidget {
  final ProfileModel profile;
  final Animation<double> animation;
  final VoidCallback onStartScreening;

  const _OceanHomeView({
    required this.profile,
    required this.animation,
    required this.onStartScreening,
  });

  @override
  State<_OceanHomeView> createState() => _OceanHomeViewState();
}

class _OceanHomeViewState extends State<_OceanHomeView> {
  static const List<_QuestProgress> _quests = [
    _QuestProgress(
      title: 'Speech Quest 1 : Sounds',
      levelsDone: 1,
      totalLevels: 4,
      score: 85,
    ),
    _QuestProgress(
      title: 'Speech Quest 2 : Practice',
      levelsDone: 0,
      totalLevels: 4,
      score: 0,
    ),
  ];

  late final ScrollController _scrollController;
  int _currentIsland = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_handleScroll);
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

  void _showProgressSummary() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return _QuestSummaryDialog(
          childName: widget.profile.childName,
          quests: _quests,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final titleTop = padding.top + (compact ? 76.0 : 14.0);
        final currentQuest = _quests[_currentIsland];

        return Stack(
          children: [
            _ScrollableOceanMap(
              animation: widget.animation,
              scrollController: _scrollController,
              onStartScreening: widget.onStartScreening,
            ),
            Positioned(
              top: padding.top + 12,
              left: 14,
              child: _ProfileChip(profile: widget.profile),
            ),
            Positioned(
              top: titleTop,
              left: compact ? 84 : 230,
              right: compact ? 84 : 230,
              child: _LessonTitle(title: currentQuest.title),
            ),
            Positioned(
              top: padding.top + 12,
              right: 14,
              child: _ProgressBadge(
                quest: currentQuest,
                onTap: _showProgressSummary,
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
  final VoidCallback? onStartScreening;

  const _ScrollableOceanMap({
    required this.animation,
    this.scrollController,
    this.onStartScreening,
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
                        _SeaweedProp(
                          animation: animation,
                          asset: 'assets/props/seaweed_13.png',
                          left: x(64),
                          top: y(400),
                          width: 21,
                          phase: 0.1,
                        ),
                        _SeaweedProp(
                          animation: animation,
                          asset: 'assets/props/seaweed_14.png',
                          left: x(252),
                          top: y(132),
                          width: 20,
                          phase: 0.45,
                        ),
                        _SeaweedProp(
                          animation: animation,
                          asset: 'assets/props/seaweed_16.png',
                          left: x(534),
                          top: y(88),
                          width: 19,
                          phase: 0.7,
                        ),
                        _SeaweedProp(
                          animation: animation,
                          asset: 'assets/props/seaweed_15.png',
                          left: x(944),
                          top: y(360),
                          width: 21,
                          phase: 0.24,
                        ),
                        _SeaweedProp(
                          animation: animation,
                          asset: 'assets/props/seaweed_17.png',
                          left: x(1088),
                          top: y(188),
                          width: 20,
                          phase: 0.62,
                        ),
                        _SeaweedProp(
                          animation: animation,
                          asset: 'assets/props/seaweed_10.png',
                          left: x(1148),
                          top: y(406),
                          width: 19,
                          phase: 0.88,
                        ),
                        _SeaweedProp(
                          animation: animation,
                          asset: 'assets/props/seaweed_11.png',
                          left: x(1600),
                          top: y(328),
                          width: 19,
                          phase: 0.3,
                        ),
                        _SeaweedProp(
                          animation: animation,
                          asset: 'assets/props/seaweed_12.png',
                          left: x(2026),
                          top: y(400),
                          width: 20,
                          phase: 0.54,
                        ),
                        _CoralProp(
                          animation: animation,
                          asset: 'assets/props/coral_01.png',
                          left: x(172),
                          top: y(376),
                          width: 26,
                          phase: 0.15,
                        ),
                        _CoralProp(
                          animation: animation,
                          asset: 'assets/props/coral_02.png',
                          left: x(324),
                          top: y(420),
                          width: 24,
                          phase: 0.42,
                        ),
                        _CoralProp(
                          animation: animation,
                          asset: 'assets/props/coral_27.png',
                          left: x(720),
                          top: y(96),
                          width: 25,
                          phase: 0.72,
                        ),
                        _CoralProp(
                          animation: animation,
                          asset: 'assets/props/coral_29.png',
                          left: x(998),
                          top: y(396),
                          width: 26,
                          phase: 0.25,
                        ),
                        _CoralProp(
                          animation: animation,
                          asset: 'assets/props/coral_04.png',
                          left: x(1208),
                          top: y(398),
                          width: 25,
                          phase: 0.58,
                        ),
                        _CoralProp(
                          animation: animation,
                          asset: 'assets/props/coral_26.png',
                          left: x(1466),
                          top: y(416),
                          width: 25,
                          phase: 0.82,
                        ),
                        _CoralProp(
                          animation: animation,
                          asset: 'assets/props/coral_28.png',
                          left: x(1832),
                          top: y(386),
                          width: 25,
                          phase: 0.33,
                        ),
                        _CoralProp(
                          animation: animation,
                          asset: 'assets/props/coral_30.png',
                          left: x(2068),
                          top: y(128),
                          width: 26,
                          phase: 0.66,
                        ),
                        _LessonSandNode(
                          animation: animation,
                          left: x(250),
                          top: y(233),
                          size: s(65),
                          active: true,
                          onTap: onStartScreening,
                        ),
                        _LessonSandNode(
                          animation: animation,
                          left: x(380),
                          top: y(163),
                          size: s(56),
                          locked: true,
                        ),
                        _LessonSandNode(
                          animation: animation,
                          left: x(548),
                          top: y(200),
                          size: s(56),
                          locked: true,
                        ),
                        _LessonSandNode(
                          animation: animation,
                          left: x(767),
                          top: y(215),
                          size: s(56),
                          locked: true,
                        ),
                        _LessonSandNode(
                          animation: animation,
                          left: x(1323),
                          top: y(237),
                          size: s(56),
                          locked: true,
                        ),
                        _LessonSandNode(
                          animation: animation,
                          left: x(1464),
                          top: y(180),
                          size: s(56),
                          locked: true,
                        ),
                        _LessonSandNode(
                          animation: animation,
                          left: x(1618),
                          top: y(231),
                          size: s(56),
                          locked: true,
                        ),
                        _LessonSandNode(
                          animation: animation,
                          left: x(1835),
                          top: y(241),
                          size: s(56),
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

  const _ProfileChip({required this.profile});

  void _showSignOutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4B4B4B),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Are you sure you want to sign out?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.read<AuthController>().signOut();
                        },
                        child: const Text(
                          'Sign Out',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: 148,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSignOutDialog(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3B7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.child_care_rounded,
                    color: Color(0xFFFF8D39),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    profile.childName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF4B4B4B),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
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

class _LessonTitle extends StatelessWidget {
  final String title;

  const _LessonTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 330),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
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
              color: Color(0xFF9557F4),
              fontSize: 18,
              fontWeight: FontWeight.w900,
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
  final int score;

  const _QuestProgress({
    required this.title,
    required this.levelsDone,
    required this.totalLevels,
    required this.score,
  });

  double get completion => totalLevels == 0 ? 0 : levelsDone / totalLevels;
}

class _ProgressBadge extends StatelessWidget {
  final _QuestProgress quest;
  final VoidCallback onTap;

  const _ProgressBadge({required this.quest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(22),
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 104,
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  color: Color(0xFF9557F4),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: quest.completion,
                  backgroundColor: const Color(0xFFE8DAFF),
                  color: const Color(0xFF9557F4),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${quest.levelsDone}/${quest.totalLevels} levels',
                style: const TextStyle(
                  color: Color(0xFF6F4ACB),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestSummaryDialog extends StatelessWidget {
  final String childName;
  final List<_QuestProgress> quests;

  const _QuestSummaryDialog({required this.childName, required this.quests});

  int get totalScore {
    if (quests.isEmpty) return 0;
    final sum = quests.fold<int>(0, (total, quest) => total + quest.score);
    return (sum / quests.length).round();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$childName summary',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4B4B4B),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textGray,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Overall score: $totalScore',
                style: const TextStyle(
                  color: Color(0xFF9557F4),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              for (final quest in quests) ...[
                _QuestSummaryRow(quest: quest),
                if (quest != quests.last) const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuestSummaryRow extends StatelessWidget {
  final _QuestProgress quest;

  const _QuestSummaryRow({required this.quest});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quest.title,
            style: const TextStyle(
              color: Color(0xFF4B4B4B),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            minHeight: 8,
            value: quest.completion,
            backgroundColor: const Color(0xFFE8DAFF),
            color: const Color(0xFF9557F4),
            borderRadius: BorderRadius.circular(999),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${quest.levelsDone}/${quest.totalLevels} levels done',
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Score ${quest.score}',
                style: const TextStyle(
                  color: Color(0xFF6F4ACB),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LessonSandNode extends StatelessWidget {
  final Animation<double> animation;
  final double left;
  final double top;
  final double size;
  final bool active;
  final bool locked;
  final VoidCallback? onTap;

  const _LessonSandNode({
    required this.animation,
    required this.left,
    required this.top,
    required this.size,
    this.active = false,
    this.locked = false,
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
          final wave = math.sin((animation.value + left / 1000) * math.pi * 2);
          final pulse = active ? 1 + (wave * 0.04) : 1.0;

          return Transform.scale(scale: pulse, child: child);
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: locked ? null : onTap,
            customBorder: const CircleBorder(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (active)
                  Image.asset(
                    'assets/props/play_button.png',
                    width: size * 0.72,
                    height: size * 0.72,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                  ),
                if (locked)
                  Container(
                    width: size * 0.74,
                    height: size * 0.74,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.94),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      color: const Color(0xFFC6C6C6),
                      size: size * 0.4,
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

class _SeaweedProp extends StatelessWidget {
  final Animation<double> animation;
  final String asset;
  final double left;
  final double? top;
  final double? bottom;
  final double width;
  final double phase;

  const _SeaweedProp({
    required this.animation,
    required this.asset,
    required this.left,
    this.top,
    this.bottom,
    required this.width,
    required this.phase,
  }) : assert(top != null || bottom != null);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final sway = math.sin((animation.value + phase) * math.pi * 2);
          return Transform.rotate(
            angle: sway * 0.035,
            alignment: Alignment.bottomCenter,
            child: Transform.translate(
              offset: Offset(sway * 2.8, 0),
              child: child,
            ),
          );
        },
        child: IgnorePointer(
          child: Image.asset(
            asset,
            width: width,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

class _CoralProp extends StatelessWidget {
  final Animation<double> animation;
  final String asset;
  final double left;
  final double top;
  final double width;
  final double phase;

  const _CoralProp({
    required this.animation,
    required this.asset,
    required this.left,
    required this.top,
    required this.width,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final bob = math.sin((animation.value + phase) * math.pi * 2);
          return Transform.translate(
            offset: Offset(0, bob * 1.6),
            child: Transform.rotate(
              angle: bob * 0.012,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          );
        },
        child: IgnorePointer(
          child: Image.asset(
            asset,
            width: width,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
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
