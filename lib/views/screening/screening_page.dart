import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/screening_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/round_action_button.dart';
import 'screening_recordings_test_page.dart';

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
  static const Color _circleGray = Color(0xFFE2E2E2);
  static const Color _iconGray = Color(0xFF7F7F7F);
  static const Color _disabledGray = Color(0xFFBDBDBD);

  Future<void> _exitScreening(ScreeningController controller) async {
    await controller.cancelAndClearAll();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<bool> _handleSystemBack(ScreeningController controller) async {
    await _exitScreening(controller);
    return false;
  }

  Future<void> _handleNext(ScreeningController controller) async {
    final finished = await controller.goNext();

    if (!mounted) return;

    if (finished) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ScreeningRecordingsTestPage(
            words: controller.words,
            recordingsByWordId: controller.recordingsByWordId,
          ),
        ),
      );
    }
  }

  Widget _buildHeader(ScreeningController controller) {
    return SizedBox(
      width: 390,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => _exitScreening(controller),
              icon: const Icon(Icons.close_rounded),
              color: const Color(0xFFC3C3C3),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Speech Sound Screening',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ScreeningController>(
      builder: (context, controller, _) {
        return WillPopScope(
          onWillPop: () => _handleSystemBack(controller),
          child: Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      children: [
                        _buildHeader(controller),
                        const SizedBox(height: 14),
                        Text(
                          '${controller.currentStep} of ${controller.totalSteps}',
                          style: const TextStyle(
                            color: AppColors.textGray,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 34),
                        Text(
                          controller.currentWord.displayWord,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 78),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            controller.isRecording
                                ? 'Recording... please wait, it will stop automatically.'
                                : controller.hasRecording
                                ? 'Would you like to record again or continue?'
                                : controller.isPromptPlaying
                                ? 'Prompt is playing... please wait before recording.'
                                : 'Tap the speaker to hear the word, then tap the microphone to record.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textGray,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        if (controller.errorMessage != null) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 390,
                            child: Text(
                              controller.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        if (!controller.hasRecording)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RoundActionButton(
                                icon: Icons.volume_up_rounded,
                                onTap: controller.canPlayPrompt
                                    ? controller.playPromptAudio
                                    : null,
                                fillColor: controller.isPromptPlaying
                                    ? AppColors.primary.withValues(alpha: 0.18)
                                    : _circleGray,
                                iconColor: controller.isPromptPlaying
                                    ? AppColors.primary
                                    : (controller.canPlayPrompt
                                          ? _iconGray
                                          : _disabledGray),
                              ),
                              const SizedBox(width: 22),
                              RoundActionButton(
                                icon: Icons.mic_rounded,
                                onTap: controller.canRecord
                                    ? controller.startTimedRecording
                                    : null,
                                fillColor: controller.isRecording
                                    ? Colors.red.withValues(alpha: 0.16)
                                    : _circleGray,
                                iconColor: controller.isRecording
                                    ? Colors.red
                                    : (controller.canRecord
                                          ? _iconGray
                                          : _disabledGray),
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              RoundActionButton(
                                icon: Icons.refresh_rounded,
                                onTap: controller.isRecording
                                    ? null
                                    : controller.repeatCurrentWord,
                                fillColor: _circleGray,
                                iconColor: controller.isRecording
                                    ? _disabledGray
                                    : _iconGray,
                              ),
                              const SizedBox(width: 22),
                              RoundActionButton(
                                icon: Icons.arrow_forward_rounded,
                                onTap: controller.isRecording
                                    ? null
                                    : () => _handleNext(controller),
                                fillColor: _circleGray,
                                iconColor: controller.isRecording
                                    ? _disabledGray
                                    : _iconGray,
                              ),
                            ],
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
