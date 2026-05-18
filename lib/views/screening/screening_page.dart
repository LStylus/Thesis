import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/screening_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/screening_word_model.dart';
import '../../widgets/glow_asset_button.dart';
import '../../widgets/ocean_auth_scaffold.dart';
import '../../widgets/primary_button.dart';
import '../auth/auth_gate.dart';
import 'screening_accuracy_results_page.dart';

class StartScreeningPage extends StatelessWidget {
  final int childAge;

  const StartScreeningPage({super.key, required this.childAge});

  void _startScreening(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ScreeningPage(childAge: childAge)),
    );
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wordCount = ScreeningWordModel.resolveForAge(childAge).length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goHome(context);
        }
      },
      child: OceanAuthScaffold(
        showMascot: false,
        topSpacing: AppSpacing.screeningTopSpacing,
        children: [
          const Text(
            'Voice Voyage\nSpeech Sound Screening',
            textAlign: TextAlign.center,
            style: AppTextStyles.screeningTitle,
          ),
          const SizedBox(height: AppSpacing.gapXs),
          const Text(
            "assess your child's speech acquisition",
            textAlign: TextAlign.center,
            style: AppTextStyles.helper,
          ),
          const SizedBox(height: 30),
          const FigmaWhaleMascot(
            width: AppSpacing.compactMascotWidth,
            height: AppSpacing.compactMascotHeight,
          ),
          const SizedBox(height: 30),
          _ScreeningFeatureList(
            items: [
              'A total of $wordCount words',
              'AI-assisted speech recognition',
              'Instant phonological accuracy results',
              'Personalized content mapping',
            ],
          ),
          const SizedBox(height: 42),
          PrimaryButton(
            text: 'Start Screening',
            onPressed: () => _startScreening(context),
          ),
          const SizedBox(height: 18),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _goHome(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Text(
                'cancel',
                textAlign: TextAlign.center,
                style: AppTextStyles.helper.copyWith(
                  color: AppColors.softTextGray,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreeningFeatureList extends StatelessWidget {
  final List<String> items;

  const _ScreeningFeatureList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    item,
                    style: AppTextStyles.helper.copyWith(fontSize: 13.5),
                  ),
                ),
              ],
            ),
            if (item != items.last) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class ScreeningPage extends StatelessWidget {
  final int childAge;

  const ScreeningPage({super.key, required this.childAge});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ScreeningController(childAge: childAge),
      child: const _ScreeningView(),
    );
  }
}

class _ScreeningView extends StatefulWidget {
  const _ScreeningView();

  @override
  State<_ScreeningView> createState() => _ScreeningViewState();
}

class _ScreeningViewState extends State<_ScreeningView> {
  static const Duration _minimumGlowDuration = Duration(milliseconds: 260);

  bool _allowPop = false;
  bool _isResettingWord = false;
  bool _isAdvancingWord = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  Future<void> _exitScreening(ScreeningController controller) async {
    await controller.cancelAndClearAll();
    if (!mounted) return;
    setState(() {
      _allowPop = true;
    });
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  Future<void> _handleNext(ScreeningController controller) async {
    final finished = await controller.goNext();

    if (!mounted) return;

    if (finished) {
      debugPrint(
        '[screening] opening_results_page words=${controller.words.length} '
        'recordings=${controller.recordingsByWordId.length} '
        'model_results=${controller.assessmentResultsByWordId.length}',
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ScreeningAccuracyResultsPage(
            words: controller.words,
            recordingsByWordId: controller.recordingsByWordId,
            assessmentResultsByWordId: controller.assessmentResultsByWordId,
          ),
        ),
      );
    }
  }

  Future<void> _runPulsedAction({
    required bool isRunning,
    required ValueSetter<bool> setFlag,
    required Future<void> Function() action,
  }) async {
    if (isRunning) return;

    setState(() {
      setFlag(true);
    });

    final stopwatch = Stopwatch()..start();
    try {
      await action();
    } finally {
      final remaining = _minimumGlowDuration - stopwatch.elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }
      if (mounted) {
        setState(() {
          setFlag(false);
        });
      }
    }
  }

  String _instructionFor(ScreeningController controller) {
    if (controller.isRecording) {
      return 'Recording... please wait, it will stop automatically.';
    }
    if (controller.isProcessing) {
      return 'Checking pronunciation with the model...';
    }
    if (controller.hasRecording) {
      return 'Tap try again to replace your recording, or tap next to continue.';
    }
    if (controller.isPromptPlaying) {
      return 'Listen to the word, then tap the microphone to record.';
    }
    return 'Tap the speaker to hear the word, then tap the microphone to record';
  }

  Widget _buildRecordingScreen(ScreeningController controller) {
    final hasRecording = controller.hasRecording;
    final controlsDisabled = controller.isRecording || controller.isProcessing;

    return OceanAuthScaffold(
      showMascot: false,
      showSandDecoration: false,
      topSpacing: AppSpacing.authTopSpacingCompact,
      bottomPadding: 28,
      leading: OceanCloseButton(onPressed: () => _exitScreening(controller)),
      children: [
        const Text(
          'Voice Voyage\nSpeech Sound Screening',
          textAlign: TextAlign.center,
          style: AppTextStyles.screeningTitle,
        ),
        const SizedBox(height: AppSpacing.gapXs),
        Text(
          '${controller.currentStep} of ${controller.totalSteps}',
          textAlign: TextAlign.center,
          style: AppTextStyles.helper.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 24),
        const FigmaWhaleMascot(
          width: AppSpacing.compactMascotWidth,
          height: AppSpacing.compactMascotHeight,
        ),
        const SizedBox(height: 20),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            controller.currentWord.displayWord.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primary,
              fontFamily: AppFonts.fredokaOne,
              fontSize: 28,
              fontWeight: FontWeight.w400,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 36),
        SizedBox(
          width: 280,
          child: Text(
            _instructionFor(controller),
            textAlign: TextAlign.center,
            style: AppTextStyles.helper,
          ),
        ),
        if (controller.errorMessage != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: 280,
            child: Text(
              controller.errorMessage!,
              textAlign: TextAlign.center,
              style: AppTextStyles.helper.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 26),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!hasRecording)
              GlowAssetButton(
                assetPath: AppAssets.playButton,
                semanticsLabel: 'Play prompt',
                isActive: controller.isPromptPlaying,
                onTap: controller.canPlayPrompt
                    ? controller.playPromptAudio
                    : null,
              )
            else
              GlowAssetButton(
                assetPath: AppAssets.tryAgainButton,
                semanticsLabel: 'Try again',
                isActive: _isResettingWord,
                onTap: controlsDisabled
                    ? null
                    : () => _runPulsedAction(
                        isRunning: _isResettingWord,
                        setFlag: (value) => _isResettingWord = value,
                        action: controller.repeatCurrentWord,
                      ),
              ),
            const SizedBox(width: 22),
            if (!hasRecording)
              GlowAssetButton(
                assetPath: AppAssets.microphoneButton,
                semanticsLabel: 'Record word',
                isActive: controller.isRecording,
                onTap: controller.canRecord
                    ? controller.startTimedRecording
                    : null,
                size: 72,
              )
            else
              GlowAssetButton(
                assetPath: AppAssets.nextButton,
                semanticsLabel: 'Next word',
                isActive: _isAdvancingWord,
                onTap: controlsDisabled
                    ? null
                    : () => _runPulsedAction(
                        isRunning: _isAdvancingWord,
                        setFlag: (value) => _isAdvancingWord = value,
                        action: () => _handleNext(controller),
                      ),
              ),
          ],
        ),
        const SizedBox(height: 34),
        const Text(
          'NOTICE!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textGray,
            fontFamily: AppFonts.fredokaOne,
            fontSize: 10,
            fontWeight: FontWeight.w400,
            height: 1,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 3),
        const SizedBox(
          width: 250,
          child: Text(
            'Please ensure your microphone is working and you are in a quiet environment.',
            textAlign: TextAlign.center,
            style: AppTextStyles.helper,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScreeningController>(
      builder: (context, controller, _) {
        return PopScope(
          canPop: _allowPop,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              _exitScreening(controller);
            }
          },
          child: _buildRecordingScreen(controller),
        );
      },
    );
  }
}
