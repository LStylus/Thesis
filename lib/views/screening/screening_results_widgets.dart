part of 'screening_accuracy_results_page.dart';

class _LandscapeLoadingView extends StatelessWidget {
  final int processedCount;
  final int totalCount;

  const _LandscapeLoadingView({
    required this.processedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? null : processedCount / totalCount;

    return VoyageFlowScaffold(
      eyebrow: 'Analyzing samples',
      title: 'Preparing results',
      subtitle: 'The recorded words are being checked for speech patterns.',
      child: _LoadingContent(
        progress: progress,
        processedCount: processedCount,
        totalCount: totalCount,
      ),
    );
  }
}

class _LoadingContent extends StatelessWidget {
  final double? progress;
  final int processedCount;
  final int totalCount;

  const _LoadingContent({
    required this.progress,
    required this.processedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCFE8EE)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Processing $processedCount of $totalCount',
                style: const TextStyle(
                  color: Color(0xFF124B63),
                  fontFamily: AppFonts.fredokaOne,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaResultTile extends StatelessWidget {
  final Model2AssessmentResult result;
  final bool isPlaying;
  final VoidCallback onPlay;

  const _FigmaResultTile({
    required this.result,
    required this.isPlaying,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final score = result.overallScore;
    final processText = result.isSuccess
        ? result.detectedProcessSummary
        : result.error ?? 'Unable to process sample';
    final detectedWord = result.detectedIpa?.trim().isNotEmpty == true
        ? result.detectedIpa!
        : result.displayWord;
    final scoreLabel = score == null
        ? 'No score'
        : '${score.toStringAsFixed(0)}%';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE8EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.displayWord.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF124B63),
                    fontFamily: AppFonts.fredokaOne,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                ),
              ),
              _PlayRecordingButton(onTap: onPlay, isActive: isPlaying),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Detected: $detectedWord',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF66818D),
              fontFamily: AppFonts.fredoka,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            processText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF426674),
              fontFamily: AppFonts.fredoka,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score == null ? 0.0 : (score / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    color: AppColors.primary,
                    backgroundColor: const Color(0xFFDCE8EC),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                scoreLabel,
                style: const TextStyle(
                  color: Color(0xFF124B63),
                  fontFamily: AppFonts.fredokaOne,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayRecordingButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;

  const _PlayRecordingButton({required this.onTap, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return GlowAssetButton(
      assetPath: AppAssets.playButton,
      semanticsLabel: 'Play recording',
      onTap: onTap,
      isActive: isActive,
      size: 43,
      glowBlur: 18,
      glowSpread: 1.5,
    );
  }
}

class _EmptyResultsMessage extends StatelessWidget {
  const _EmptyResultsMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'No screening samples were processed.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textGray,
          fontFamily: AppFonts.fredoka,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
