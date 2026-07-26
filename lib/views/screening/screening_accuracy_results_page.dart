import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/screening_word_model.dart';
import '../../services/phoneme_assessment_service.dart';
import '../../widgets/glow_asset_button.dart';
import '../../widgets/ocean_auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../auth/auth_gate.dart';

class ScreeningAccuracyResultsPage extends StatefulWidget {
  final List<ScreeningWordModel> words;
  final Map<String, String> recordingsByWordId;
  final Map<String, PhonemeAssessmentResult> assessmentResultsByWordId;
  final int childAge;

  const ScreeningAccuracyResultsPage({
    super.key,
    required this.words,
    required this.recordingsByWordId,
    required this.assessmentResultsByWordId,
    required this.childAge,
  });

  @override
  State<ScreeningAccuracyResultsPage> createState() =>
      _ScreeningAccuracyResultsPageState();
}

class _ScreeningAccuracyResultsPageState
    extends State<ScreeningAccuracyResultsPage> {
  final PhonemeAssessmentService _assessmentService = PhonemeAssessmentService();
  final AudioPlayer _player = AudioPlayer();
  final List<PhonemeAssessmentResult> _results = [];

  bool _isRunning = true;
  bool _isSavingProfile = false;
  int _processedCount = 0;
  String? _playingWordId;
  String? _profileSaveError;
  int _playbackSession = 0;

  @override
  void initState() {
    super.initState();
    _forcePortrait();
    _runAssessments();
  }

  static Future<void> _forcePortrait() {
    return SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _runAssessments() async {
    debugPrint(
      '[screening-api] run_start words=${widget.words.length} '
      'recordings=${widget.recordingsByWordId.length} '
      'precomputed_results=${widget.assessmentResultsByWordId.length} '
      'base_url=${_assessmentService.baseUrl}',
    );

    for (final word in widget.words) {
      final recordingPath = widget.recordingsByWordId[word.id];
      final precomputedResult = widget.assessmentResultsByWordId[word.id];
      debugPrint(
        '[screening-api] queue_word word=${word.displayWord} '
        'word_id=${word.id} has_recording=${recordingPath != null} '
        'has_precomputed_result=${precomputedResult != null}',
      );

      final PhonemeAssessmentResult result;
      if (precomputedResult != null) {
        result = precomputedResult;
        final score = result.overallScore?.toStringAsFixed(2);
        debugPrint(
          '[screening-api] using_precomputed_result '
          'word=${result.displayWord} word_id=${result.wordId} '
          'score=$score process_count=${result.detectedProcesses.length} '
          'processes=${result.detectedProcessSummary}',
        );
      } else if (recordingPath == null) {
        result = PhonemeAssessmentResult.failure(
          word: word,
          recordingPath: '',
          error: 'No recording was captured for this word.',
        );
      } else {
        debugPrint(
          '[screening-api] fallback_assess_start word=${word.displayWord} '
          'word_id=${word.id} path=$recordingPath',
        );
        result = await _assessmentService.assess(
          word: word,
          recordingPath: recordingPath,
          age: widget.childAge,
        );
      }

      _logDetectedProcesses(result);

      if (!mounted) return;
      setState(() {
        _results.add(result);
        _processedCount++;
      });
    }

    final filePath = await _writeTemporaryResultsFile();
    debugPrint(
      '[screening-api] run_complete processed=$_processedCount '
      'detected_processes=${_detectedProcessesForPayload.length} '
      'result_file=$filePath',
    );
    if (!mounted) return;

    setState(() {
      _isRunning = false;
    });
  }

  Future<String> _writeTemporaryResultsFile() async {
    final tempDir = await getTemporaryDirectory();
    final file = File(
      '${tempDir.path}/voice_voyage_model_2_results_'
      '${DateTime.now().millisecondsSinceEpoch}.json',
    );

    final payload = {
      'generated_at': DateTime.now().toIso8601String(),
      'model': 'Model-2',
      'model_base_url': _assessmentService.baseUrl,
      'average_accuracy': _averageAccuracy,
      'detected_processes': _detectedProcessesForPayload,
      'results': _results.map((result) => result.toJson()).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(payload));
    return file.path;
  }

  double? get _averageAccuracy {
    final scores = _results
        .map((result) => result.overallScore)
        .whereType<double>()
        .toList();

    if (scores.isEmpty) return null;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  List<Map<String, dynamic>> get _detectedProcessesForPayload {
    return _results.expand((result) {
      return result.detectedProcesses.map((process) {
        return {
          'word_id': result.wordId,
          'display_word': result.displayWord,
          ...process,
        };
      });
    }).toList();
  }

  void _logDetectedProcesses(PhonemeAssessmentResult result) {
    final prefix =
        '[screening-api] word=${result.displayWord} word_id=${result.wordId}';

    if (!result.isSuccess) {
      debugPrint('$prefix status=error message=${result.error}');
      return;
    }

    if (result.detectedProcesses.isEmpty) {
      debugPrint('$prefix detected_processes=[]');
      return;
    }

    for (final process in result.detectedProcesses) {
      final name = process['process'];
      final position = process['position'];
      final detail = process['detail'];
      debugPrint('$prefix process=$name position=$position detail=$detail');
    }
  }

  Future<void> _playRecording(PhonemeAssessmentResult result) async {
    final path = result.recordingPath;
    if (path.isEmpty) return;

    final file = File(path);
    if (!await file.exists()) return;

    final session = ++_playbackSession;
    if (mounted) {
      setState(() {
        _playingWordId = result.wordId;
      });
    }

    try {
      await _player.stop();
      final completion = _player.onPlayerComplete.first;
      await _player.play(DeviceFileSource(path));
      await completion.timeout(const Duration(seconds: 20));
    } catch (error) {
      debugPrint('[screening-results] play_recording_error=$error path=$path');
    } finally {
      if (mounted && session == _playbackSession) {
        setState(() {
          _playingWordId = null;
        });
      }
    }
  }

  Future<void> _discardAndGoHome() async {
    final authController = context.read<AuthController>();
    final isExisting = authController.isExistingParentSession;

    await authController.discardPendingProfile();
    if (!mounted) return;

    if (isExisting) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    }
  }

  Future<void> _proceedToHome() async {
    if (_isSavingProfile) return;

    setState(() {
      _isSavingProfile = true;
      _profileSaveError = null;
    });

    final authController = context.read<AuthController>();
    final saved = await authController.completeSignup();
    if (!mounted) return;

    if (!saved) {
      setState(() {
        _isSavingProfile = false;
        _profileSaveError =
            authController.errorMessage ?? 'Could not save profile data.';
      });
      return;
    }

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _playbackSession++;
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isRunning) {
      return _LandscapeLoadingView(
        processedCount: _processedCount,
        totalCount: widget.words.length,
      );
    }

    return OceanAuthScaffold(
      showMascot: false,
      showSandDecoration: false,
      topSpacing: AppSpacing.authTopSpacingCompact,
      bottomPadding: 28,
      leading: OceanCloseButton(onPressed: _discardAndGoHome),
      children: [
        const Text(
          'Screening Results',
          textAlign: TextAlign.center,
          style: AppTextStyles.screeningTitle,
        ),
        const SizedBox(height: 7),
        const Text(
          'Detected Phonological Processes',
          textAlign: TextAlign.center,
          style: AppTextStyles.helper,
        ),
        const SizedBox(height: 34),
        if (_results.isEmpty)
          const _EmptyResultsMessage()
        else
          ..._results.map(
            (result) => _FigmaResultTile(
              result: result,
              isPlaying: _playingWordId == result.wordId,
              onPlay: () => _playRecording(result),
            ),
          ),
        const SizedBox(height: 22),
        PrimaryButton(
          text: 'Proceed',
          onPressed: _isSavingProfile ? null : _proceedToHome,
          isLoading: _isSavingProfile,
        ),
        if (_profileSaveError != null) ...[
          const SizedBox(height: 12),
          Text(
            _profileSaveError!,
            textAlign: TextAlign.center,
            style: AppTextStyles.helper.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 560;
                  final whale = const FigmaWhaleMascot(width: 210, height: 116);
                  final content = _LoadingContent(
                    progress: progress,
                    processedCount: processedCount,
                    totalCount: totalCount,
                  );

                  if (!isWide) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [whale, const SizedBox(height: 22), content],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      whale,
                      const SizedBox(width: 54),
                      Flexible(child: content),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
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
    return SizedBox(
      width: 390,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Screening Results',
            textAlign: TextAlign.left,
            style: TextStyle(
              color: AppColors.primary,
              fontFamily: AppFonts.fredokaOne,
              fontSize: 28,
              fontWeight: FontWeight.w400,
              height: 1,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Detected phonological processes are being prepared.',
            style: TextStyle(
              color: AppColors.textGray,
              fontFamily: AppFonts.fredoka,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.2,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Processing $processedCount / $totalCount',
            style: const TextStyle(
              color: AppColors.textGray,
              fontFamily: AppFonts.fredokaOne,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _FigmaResultTile extends StatelessWidget {
  final PhonemeAssessmentResult result;
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.displayWord.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontFamily: AppFonts.fredokaOne,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Detected Word: $detectedWord',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontFamily: AppFonts.fredoka,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Process: $processText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textGray,
                    fontFamily: AppFonts.fredoka,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: score == null ? 0.0 : (score / 100).clamp(0.0, 1.0),
                    minHeight: 4,
                    color: AppColors.primary,
                    backgroundColor: const Color(0xFFE3E3E3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          _PlayRecordingButton(
            onTap: onPlay,
            isActive: isPlaying,
          ),
        ],
      ),
    );
  }
}

class _PlayRecordingButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;

  const _PlayRecordingButton({
    required this.onTap,
    required this.isActive,
  });

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
