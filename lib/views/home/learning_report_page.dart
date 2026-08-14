import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/learning_report_model.dart';
import '../../models/profile_model.dart';
import '../../widgets/profile_avatar.dart';

part 'learning_report_widgets.dart';

class LearningReportMetrics {
  final int activities;
  final int minutes;
  final int words;
  final int levels;
  final int? averageAccuracy;

  const LearningReportMetrics({
    required this.activities,
    required this.minutes,
    required this.words,
    required this.levels,
    this.averageAccuracy,
  });
}

class LearningReportPage extends StatefulWidget {
  final ProfileModel profile;
  final LearningReportMetrics thisWeek;
  final LearningReportMetrics overall;
  final LearningReportData reportData;

  const LearningReportPage({
    super.key,
    required this.profile,
    required this.thisWeek,
    required this.overall,
    required this.reportData,
  });

  @override
  State<LearningReportPage> createState() => _LearningReportPageState();
}

class _LearningReportPageState extends State<LearningReportPage> {
  static const Color _cardBorder = Color(0xFFEDEDED);
  static const Color _darkText = Color(0xFF4D4D4D);
  static const Color _mutedText = Color(0xFF8D8D8D);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.white,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final edgePadding = (constraints.maxWidth * 0.04)
                  .clamp(24.0, 42.0)
                  .toDouble();
              final sidebarWidth = (constraints.maxWidth * 0.28)
                  .clamp(220.0, 310.0)
                  .toDouble();

              return Padding(
                padding: EdgeInsets.all(edgePadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: sidebarWidth,
                      child: _ReportSidebar(
                        profile: widget.profile,
                        onBack: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Learning Report',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                color: AppColors.primary,
                                fontFamily: AppFonts.fredokaOne,
                                fontSize: 26,
                                fontWeight: FontWeight.w400,
                                height: 1.1,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _ReportCard(
                                    title: 'This Week',
                                    minContentHeight: 122,
                                    child: _MetricsGrid(
                                      metrics: widget.thisWeek,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _ReportCard(
                                    title: 'Overall Progress',
                                    minContentHeight: 122,
                                    child: _MetricsGrid(
                                      metrics: widget.overall,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _ReportCard(
                              title: 'Level Scores',
                              minContentHeight: 118,
                              child: _LevelScoresList(
                                scores: widget.reportData.levelScores,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
