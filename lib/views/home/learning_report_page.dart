import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/profile_model.dart';
import '../../widgets/profile_avatar.dart';

class LearningReportMetrics {
  final int activities;
  final int minutes;
  final int words;
  final int levels;

  const LearningReportMetrics({
    required this.activities,
    required this.minutes,
    required this.words,
    required this.levels,
  });
}

class LearningReportPage extends StatefulWidget {
  final ProfileModel profile;
  final LearningReportMetrics thisWeek;
  final LearningReportMetrics overall;

  const LearningReportPage({
    super.key,
    required this.profile,
    required this.thisWeek,
    required this.overall,
  });

  @override
  State<LearningReportPage> createState() => _LearningReportPageState();
}

class _LearningReportPageState extends State<LearningReportPage> {
  static const Color _screenGray = Color(0xFFD3D3D3);
  static const Color _cardBorder = Color(0xFFEDEDED);
  static const Color _darkText = Color(0xFF4D4D4D);
  static const Color _mutedText = Color(0xFF8D8D8D);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: _screenGray,
        systemNavigationBarColor: _screenGray,
      ),
      child: Scaffold(
        backgroundColor: _screenGray,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final panelWidth = math.min(constraints.maxWidth - 40, 300.0);
              final safePanelWidth = math.max(panelWidth, 248.0);
              final panelHeight = math.max(constraints.maxHeight - 38, 560.0);

              return Stack(
                children: [
                  const Positioned(
                    top: 6,
                    left: 20,
                    child: Text(
                      'progress',
                      style: TextStyle(
                        color: Color(0xFF747474),
                        fontFamily: AppFonts.fredoka,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    top: 26,
                    bottom: 10,
                    child: Center(
                      child: SingleChildScrollView(
                        child: Container(
                          width: safePanelWidth,
                          constraints: BoxConstraints(minHeight: panelHeight),
                          color: Colors.white,
                          padding: const EdgeInsets.fromLTRB(17, 12, 17, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Learning Report',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontFamily: AppFonts.fredokaOne,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  height: 1.1,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _ProfileHeader(profile: widget.profile),
                              const SizedBox(height: 17),
                              _ReportCard(
                                title: 'This Week',
                                child: _MetricsGrid(metrics: widget.thisWeek),
                              ),
                              const SizedBox(height: 16),
                              const _ReportCard(
                                title: 'Phonological Process',
                                minContentHeight: 73,
                                child: SizedBox.shrink(),
                              ),
                              const SizedBox(height: 16),
                              _ReportCard(
                                title: 'Overall Progress',
                                child: Column(
                                  children: [
                                    const SizedBox(height: 7),
                                    const Text(
                                      'So far, your child has learned',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFFC9C9C9),
                                        fontFamily: AppFonts.fredokaOne,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    _MetricsGrid(metrics: widget.overall),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _PlayButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ProfileModel profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileAvatar(
          assetPath: profile.profileAssetPath,
          fallbackSeed: profile.profileId,
          size: 58,
          borderWidth: 1.5,
          borderRadius: 29,
          borderColor: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.childName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _LearningReportPageState._darkText,
                  fontFamily: AppFonts.fredokaOne,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.1,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Age: ${profile.age} yrs old',
                style: const TextStyle(
                  color: _LearningReportPageState._darkText,
                  fontFamily: AppFonts.fredoka,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Start Date: ${_formatMonthYear(DateTime.now())}',
                style: const TextStyle(
                  color: _LearningReportPageState._darkText,
                  fontFamily: AppFonts.fredoka,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatMonthYear(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '$month/${date.year}';
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final Widget child;
  final double minContentHeight;

  const _ReportCard({
    required this.title,
    required this.child,
    this.minContentHeight = 76,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _LearningReportPageState._cardBorder,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 28,
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _LearningReportPageState._darkText,
                  fontFamily: AppFonts.fredokaOne,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const Divider(height: 1, thickness: 0.8, color: Color(0xFFE8E8E8)),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final LearningReportMetrics metrics;

  const _MetricsGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricItem(
                color: AppColors.primary,
                label: 'Activities',
                value: metrics.activities,
              ),
            ),
            Expanded(
              child: _MetricItem(
                color: const Color(0xFFFF8845),
                label: 'Minutes',
                value: metrics.minutes,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricItem(
                color: const Color(0xFFF15D77),
                label: 'Words',
                value: metrics.words,
              ),
            ),
            Expanded(
              child: _MetricItem(
                color: const Color(0xFFFFC928),
                label: 'Levels',
                value: metrics.levels,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  final Color color;
  final String label;
  final int value;

  const _MetricItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 21,
          height: 21,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _LearningReportPageState._darkText,
                  fontFamily: AppFonts.fredoka,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  letterSpacing: 0,
                ),
              ),
              Text(
                '$value',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _LearningReportPageState._mutedText,
                  fontFamily: AppFonts.fredoka,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _PlayButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0098CC).withValues(alpha: 0.8),
            blurRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(24),
          child: const SizedBox(
            height: 39,
            child: Center(
              child: Text(
                'Play',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: AppFonts.fredokaOne,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
