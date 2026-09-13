import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/screening_controller.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../models/screening_word_model.dart';
import '../../widgets/countdown_mic_button.dart';
import '../../widgets/credentials_auth_scaffold.dart';
import '../../widgets/glow_asset_button.dart';
import '../../widgets/primary_button.dart';
import '../auth/auth_gate.dart';
import 'screening_accuracy_results_page.dart';

class StartScreeningPage extends StatefulWidget {
  final int childAge;

  const StartScreeningPage({super.key, required this.childAge});

  @override
  State<StartScreeningPage> createState() => _StartScreeningPageState();
}

class _StartScreeningPageState extends State<StartScreeningPage> {
  void _startScreening(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ScreeningPage(childAge: widget.childAge),
      ),
    );
  }

  Future<void> _goHome(BuildContext context) async {
    final authController = context.read<AuthController>();
    final isExisting = authController.isExistingParentSession;

    await authController.discardPendingProfile();
    if (!context.mounted) return;

    if (isExisting) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordCount = ScreeningWordModel.resolveForAge(widget.childAge).length;
    final dense = MediaQuery.sizeOf(context).height < 420;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _goHome(context);
        }
      },
      child: VoyageFlowScaffold(
        eyebrow: 'Baseline check',
        onClose: () => _goHome(context),
        title: 'Speech sound screening',
        subtitle: 'A short baseline before the first practice voyage.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScreeningSummaryPanel(
              wordCount: wordCount,
              childAge: widget.childAge,
            ),
            SizedBox(height: dense ? 10 : 20),
            PrimaryButton(
              text: 'Start screening',
              onPressed: () => _startScreening(context),
              height: dense ? 48 : 56,
              borderRadius: 8,
              trailingIcon: Icons.arrow_forward_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScreeningSummaryPanel extends StatelessWidget {
  final int wordCount;
  final int childAge;

  const _ScreeningSummaryPanel({
    required this.wordCount,
    required this.childAge,
  });

  @override
  Widget build(BuildContext context) {
    final dense = MediaQuery.sizeOf(context).height < 420;

    return Container(
      padding: EdgeInsets.all(dense ? 10 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCFE8EE)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ScreeningStat(
              icon: Icons.format_list_numbered_rounded,
              value: '$wordCount',
              label: 'words',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ScreeningStat(
              icon: Icons.child_care_rounded,
              value: '$childAge',
              label: 'years old',
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: _ScreeningStat(
              icon: Icons.mic_none_rounded,
              value: 'Quiet',
              label: 'recording space',
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreeningStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _ScreeningStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final dense = MediaQuery.sizeOf(context).height < 420;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primaryShadow, size: dense ? 20 : 24),
        SizedBox(height: dense ? 3 : 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: const Color(0xFF124B63),
              fontFamily: AppFonts.fredokaOne,
              fontSize: dense ? 15 : 18,
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF66818D),
            fontFamily: AppFonts.fredoka,
            fontSize: dense ? 10 : 11.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
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

  Future<void> _exitScreening(ScreeningController controller) async {
    final authController = context.read<AuthController>();
    final isExisting = authController.isExistingParentSession;

    await controller.cancelAndClearAll();
    if (!mounted) return;
    await authController.discardPendingProfile();
    if (!mounted) return;

    if (isExisting) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (route) => false,
      );
    } else {
      setState(() {
        _allowPop = true;
      });
      Navigator.of(context).pop();
    }
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
    return 'Say ${controller.currentWord.displayWord}. Tap the microphone to record. '
        'Temporary captions replace voice-over.';
  }

  Widget _buildRecordingScreen(ScreeningController controller) {
    final hasRecording = controller.hasRecording;
    final controlsDisabled = controller.isRecording || controller.isProcessing;
    final dense = MediaQuery.sizeOf(context).height < 420;
    final controlSize = dense ? 60.0 : 72.0;

    return VoyageFlowScaffold(
      currentStep: controller.currentStep,
      totalSteps: controller.totalSteps,
      onClose: () => _exitScreening(controller),
      title: 'Say the word',
      subtitle: _instructionFor(controller),
      contentMaxWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 14 : 20,
              vertical: dense ? 10 : 16,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF2FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCFE8EE)),
            ),
            child: Row(
              children: [
                Container(
                  width: dense ? 36 : 44,
                  height: dense ? 36 : 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    controller.isProcessing
                        ? Icons.graphic_eq_rounded
                        : Icons.record_voice_over_outlined,
                    color: controller.isProcessing
                        ? const Color(0xFFE49A2F)
                        : AppColors.primaryShadow,
                    size: dense ? 21 : 25,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      controller.currentWord.displayWord.toUpperCase(),
                      style: TextStyle(
                        color: const Color(0xFF124B63),
                        fontFamily: AppFonts.fredokaOne,
                        fontSize: dense ? 32 : 42,
                        fontWeight: FontWeight.w400,
                        height: 1,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                if (controller.isRecording)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEF1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${controller.recordingCountdown}s',
                      style: const TextStyle(
                        color: Color(0xFFC8485E),
                        fontFamily: AppFonts.fredokaOne,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 10),
            CredentialsErrorBanner(message: controller.errorMessage!),
          ],
          SizedBox(height: dense ? 10 : 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasRecording)
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
                  size: controlSize,
                ),
              if (hasRecording) const SizedBox(width: 20),
              if (controller.isProcessing)
                RecordingMicButton(
                  isPending: false,
                  isRecording: false,
                  isProcessing: true,
                  progress: controller.recordingProgress,
                  countdown: controller.recordingCountdown,
                  size: controlSize,
                )
              else if (!hasRecording)
                RecordingMicButton(
                  isPending: false,
                  isRecording: controller.isRecording,
                  isProcessing: false,
                  progress: controller.recordingProgress,
                  countdown: controller.recordingCountdown,
                  onTap: controller.canRecord
                      ? controller.startTimedRecording
                      : null,
                  size: controlSize,
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
                  size: controlSize,
                ),
            ],
          ),
          SizedBox(height: dense ? 8 : 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF78909A),
                size: 17,
              ),
              SizedBox(width: 7),
              Flexible(
                child: Text(
                  'Record in a quiet space with the microphone unobstructed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF78909A),
                    fontFamily: AppFonts.fredoka,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
