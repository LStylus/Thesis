part of 'learning_report_page.dart';

class _ReportSidebar extends StatelessWidget {
  final ProfileModel profile;
  final VoidCallback onBack;

  const _ReportSidebar({required this.profile, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FDFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1F7FF)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(profile: profile),
            const Spacer(),
            _PlayButton(label: 'Back to Map', onPressed: onBack),
          ],
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
                label: metrics.averageAccuracy == null ? 'Levels' : 'Accuracy',
                value: metrics.averageAccuracy ?? metrics.levels,
                suffix: metrics.averageAccuracy == null ? '' : '%',
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
  final String suffix;

  const _MetricItem({
    required this.color,
    required this.label,
    required this.value,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
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
                '$value$suffix',
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

class _LevelScoresList extends StatelessWidget {
  final List<LearningReportLevelScore> scores;

  const _LevelScoresList({required this.scores});

  @override
  Widget build(BuildContext context) {
    if (scores.isEmpty) {
      return const Center(
        child: Text(
          'No completed levels yet.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _LearningReportPageState._mutedText,
            fontFamily: AppFonts.fredoka,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final score in scores) ...[
          _LevelScoreRow(score: score),
          if (score != scores.last)
            const Divider(height: 13, thickness: 0.7, color: Color(0xFFEDEDED)),
        ],
      ],
    );
  }
}

class _LevelScoreRow extends StatelessWidget {
  final LearningReportLevelScore score;

  const _LevelScoreRow({required this.score});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Activity ${score.activityIndex + 1} - Level ${score.levelIndex + 1}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _LearningReportPageState._darkText,
              fontFamily: AppFonts.fredoka,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ),
        Container(
          height: 25,
          constraints: const BoxConstraints(minWidth: 58),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${score.accuracy}%',
            style: const TextStyle(
              color: AppColors.primary,
              fontFamily: AppFonts.fredokaOne,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PlayButton({required this.label, required this.onPressed});

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
          child: SizedBox(
            height: 39,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
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
