import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../controllers/screening_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';
import '../../widgets/ocean_auth_scaffold.dart';
import 'screening_accuracy_results_page.dart';

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
  bool _allowPop = false;

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
    Navigator.pop(context);
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _FigmaCloseButton(
                      onPressed: () => _exitScreening(controller),
                    ),
                  ),
                  const SizedBox(height: 42),
                  const Text(
                    'Voice Voyage\nSpeech Sound Screening',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontFamily: AppFonts.fredokaOne,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                      height: 1.02,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${controller.currentStep} of ${controller.totalSteps}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontFamily: AppFonts.fredoka,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const FigmaWhaleMascot(width: 194, height: 108),
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
                  const SizedBox(height: 50),
                  SizedBox(
                    width: 252,
                    child: Text(
                      _instructionFor(controller),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontFamily: AppFonts.fredoka,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.15,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  if (controller.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 280,
                      child: Text(
                        controller.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontFamily: AppFonts.fredoka,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!hasRecording)
                        _ScreeningIconButton(
                          assetPath: 'assets/icons/play_button.png',
                          semanticsLabel: 'Play prompt',
                          onTap: controller.canPlayPrompt
                              ? controller.playPromptAudio
                              : null,
                        )
                      else
                        _ScreeningIconButton(
                          assetPath: 'assets/icons/try_again_button.png',
                          semanticsLabel: 'Try again',
                          onTap: controlsDisabled
                              ? null
                              : controller.repeatCurrentWord,
                        ),
                      const SizedBox(width: 22),
                      if (!hasRecording)
                        _ScreeningIconButton(
                          assetPath: 'assets/icons/microphone_button.png',
                          semanticsLabel: 'Record word',
                          onTap: controller.canRecord
                              ? controller.startTimedRecording
                              : null,
                          size: 72,
                        )
                      else
                        _ScreeningIconButton(
                          assetPath: 'assets/icons/next_button.png',
                          semanticsLabel: 'Next word',
                          onTap: controlsDisabled
                              ? null
                              : () => _handleNext(controller),
                        ),
                    ],
                  ),
                  const SizedBox(height: 36),
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
                    width: 230,
                    child: Text(
                      'Please ensure your microphone\nis working and in a quiet environment',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontFamily: AppFonts.fredoka,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        height: 1.14,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

class _FigmaCloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _FigmaCloseButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Close',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFD7D7D7),
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _ScreeningIconButton extends StatelessWidget {
  final String assetPath;
  final String semanticsLabel;
  final VoidCallback? onTap;
  final double size;

  const _ScreeningIconButton({
    required this.assetPath,
    required this.semanticsLabel,
    required this.onTap,
    this.size = 68,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.45 : 1,
          child: SizedBox(
            width: size,
            height: size,
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}
