import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../controllers/home_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/learning_report_model.dart';
import '../../models/profile_model.dart';
import '../../features/game/presentation/game_screen.dart';
import '../../services/audio_recording_service.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/voyage_loading_screen.dart';
import 'learning_report_page.dart';
import 'user_select_page.dart';

part 'home_map_widgets.dart';
part 'home_profile_widgets.dart';
part 'home_progress_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motionController;
  bool _isInitialLoading = true;

  static Future<void> lockLandscape() {
    return SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void initState() {
    super.initState();
    lockLandscape();
    final homeController = context.read<HomeController>();
    homeController.ensureCurrentUserProfileAssets().catchError((error) {
      debugPrint('Profile asset backfill failed: $error');
    });
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    unawaited(_completeInitialLoading());
  }

  Future<void> _completeInitialLoading() async {
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 850)),
      _warmUpMicrophonePermission(),
    ]);

    if (!mounted) return;
    setState(() {
      _isInitialLoading = false;
    });
  }

  Future<void> _warmUpMicrophonePermission() async {
    final recordingService = AudioRecordingService();
    try {
      final ready = await recordingService.initialize();
      debugPrint(
        '[home] microphone_warmup ready=$ready '
        'has_permission=${recordingService.hasMicPermission}',
      );
    } catch (error) {
      debugPrint('[home] microphone_warmup_error error=$error');
    } finally {
      await recordingService.dispose();
    }
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeController = context.read<HomeController>();

    if (_isInitialLoading) {
      return const VoyageLoadingScreen(
        message: 'Preparing microphone\nand learning map...',
      );
    }

    return StreamBuilder<ProfileModel?>(
      stream: homeController.currentUserProfileStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const VoyageLoadingScreen();
        }

        final profile = snapshot.data;

        if (profile == null) {
          return Scaffold(
            body: _SkyIslandShell(
              animation: _motionController,
              child: const Center(child: _EmptyProfileMessage()),
            ),
          );
        }

        return Scaffold(
          body: _SkyIslandHomeView(
            profile: profile,
            animation: _motionController,
          ),
        );
      },
    );
  }
}

class _SkyIslandHomeView extends StatefulWidget {
  final ProfileModel profile;
  final Animation<double> animation;

  const _SkyIslandHomeView({required this.profile, required this.animation});

  @override
  State<_SkyIslandHomeView> createState() => _SkyIslandHomeViewState();
}

class _SkyIslandHomeViewState extends State<_SkyIslandHomeView> {
  static const int _islandOneTotalLevels = 4;

  late final ScrollController _scrollController;
  final Map<int, int> _localIslandOneAccuracies = {};
  ProfileModel? _selectedProfileOverride;
  int _currentIsland = 0;

  ProfileModel get _activeProfile => _selectedProfileOverride ?? widget.profile;

  LearningReportData get _localReportData {
    return LearningReportData(
      levelScores: _localIslandOneAccuracies.entries
          .map(
            (entry) => LearningReportLevelScore(
              activityIndex: 0,
              levelIndex: entry.key,
              accuracy: entry.value,
              completedAt: DateTime.now(),
            ),
          )
          .toList(),
    );
  }

  List<_QuestProgress> _questsFor(LearningReportData reportData) {
    final completedCount = reportData.completedLevelsForActivity(0).length;

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
  void didUpdateWidget(covariant _SkyIslandHomeView oldWidget) {
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
    _localIslandOneAccuracies.clear();
    _currentIsland = 0;
  }

  Future<void> _openUserSelect(List<ProfileModel> profiles) async {
    final activeProfile = _activeProfile;
    final selectedProfile = await Navigator.of(context).push<ProfileModel>(
      MaterialPageRoute(
        builder: (_) =>
            UserSelectPage(activeProfile: activeProfile, profiles: profiles),
      ),
    );

    await _HomePageState.lockLandscape();

    if (!mounted || selectedProfile == null) return;

    setState(() {
      if (selectedProfile.profileId != _activeProfile.profileId) {
        _resetLocalProgress();
      }
      _selectedProfileOverride = selectedProfile;
    });
  }

  LearningReportMetrics _reportMetricsFor(LearningReportData reportData) {
    final completedLevels = reportData.completedLevelCount;

    return LearningReportMetrics(
      activities: 2,
      minutes: reportData.practiceMinutes,
      words: reportData.learnedWordCount,
      levels: completedLevels,
      averageAccuracy: reportData.averageAccuracy,
    );
  }

  int _unlockedIslandOneLevelsFor(LearningReportData reportData) {
    final completedLevels = reportData.completedLevelsForActivity(0);
    if (completedLevels.isEmpty) return 1;
    final highestCompletedLevel = completedLevels.reduce(math.max);
    return math.min(_islandOneTotalLevels, highestCompletedLevel + 2);
  }

  Future<void> _openLearningReport(LearningReportData reportData) async {
    final activeProfile = _activeProfile;
    final reportMetrics = _reportMetricsFor(reportData);

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LearningReportPage(
          profile: activeProfile,
          thisWeek: reportMetrics,
          overall: reportMetrics,
          reportData: reportData,
        ),
      ),
    );
  }

  Future<void> _openGameplayLevel(int levelIndex) async {
    final activeProfile = _activeProfile;
    final result = await Navigator.of(context).push<GameResult>(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          childProfileId: activeProfile.profileId,
          childName: activeProfile.childName,
          childAge: activeProfile.age,
          levelIndex: levelIndex,
          speechProfile: activeProfile.speechProfile,
        ),
      ),
    );

    if (!mounted || result == null || !result.correct) return;

    setState(() {
      _localIslandOneAccuracies[result.levelIndex] = result.accuracy;
    });

    context
        .read<HomeController>()
        .saveGameplayLevelScore(
          profile: activeProfile,
          levelIndex: result.levelIndex,
          accuracy: result.accuracy,
        )
        .catchError((error) {
          debugPrint('Saving gameplay level score failed: $error');
        });
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final activeProfile = _activeProfile;

    return StreamBuilder<LearningReportData>(
      stream: context.read<HomeController>().learningReportStream(
        activeProfile,
      ),
      builder: (context, snapshot) {
        final reportData = (snapshot.data ?? LearningReportData.empty).merge(
          _localReportData,
        );
        final quests = _questsFor(reportData);
        final currentQuest = quests[_currentIsland.clamp(0, quests.length - 1)];
        final completedIslandOneLevels = reportData.completedLevelsForActivity(
          0,
        );
        final unlockedIslandOneLevels = _unlockedIslandOneLevelsFor(reportData);

        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            final titleTop = padding.top + (compact ? 76.0 : 26.0);

            return Stack(
              children: [
                _FloatingIslandMap(
                  animation: widget.animation,
                  scrollController: _scrollController,
                  unlockedIslandOneLevels: unlockedIslandOneLevels,
                  completedIslandOneLevels: completedIslandOneLevels,
                  onStartGameplay: _openGameplayLevel,
                ),
                Positioned(
                  top: padding.top + (compact ? 18 : 30),
                  left: compact ? 18 : 40,
                  child: StreamBuilder<List<ProfileModel>>(
                    stream: context
                        .read<HomeController>()
                        .childProfilesStream(),
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
                    activityNumber: _currentIsland + 1,
                    activityCount: quests.length,
                    onTap: () => _openLearningReport(reportData),
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
                    onTap: () => _openLearningReport(reportData),
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
      },
    );
  }
}
