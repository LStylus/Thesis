import 'package:flutter/material.dart';

import '../../controllers/screening_controller.dart';
import '../auth/auth_gate.dart';
import 'screening_recordings_test_page.dart';

class ScreeningPage extends StatefulWidget {
  final int childAge;

  const ScreeningPage({super.key, required this.childAge});

  @override
  State<ScreeningPage> createState() => _ScreeningPageState();
}

class _ScreeningPageState extends State<ScreeningPage> {
  late final ScreeningController _controller;

  static const Color _primaryBlue = Color(0xFF12B5EA);
  static const Color _textGray = Color(0xFF8D8D8D);
  static const Color _bgColor = Color(0xFFF3F3F3);
  static const Color _circleGray = Color(0xFFE2E2E2);
  static const Color _iconGray = Color(0xFF7F7F7F);
  static const Color _disabledGray = Color(0xFFBDBDBD);

  @override
  void initState() {
    super.initState();
    _controller = ScreeningController(childAge: widget.childAge);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _exitScreening() async {
    await _controller.cancelAndClearAll();
    if (!mounted) return;
    Navigator.pop(context);
  }

  Future<bool> _handleSystemBack() async {
    await _exitScreening();
    return false;
  }

  // Future<void> _handleNext() async {
  //   final finished = await _controller.goNext();

  //   if (!mounted) return;

  //   if (finished) {
  //     Navigator.of(context).pushAndRemoveUntil(
  //       MaterialPageRoute(builder: (_) => const AuthGate()),
  //       (route) => false,
  //     );
  //   }
  // }

  //will delete
  Future<void> _handleNext() async {
    final finished = await _controller.goNext();

    if (!mounted) return;

    if (finished) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ScreeningRecordingsTestPage(
            words: _controller.words,
            recordingsByWordId: _controller.recordingsByWordId,
          ),
        ),
      );
    }
  }

  Widget _roundActionButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color fillColor,
    required Color iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: fillColor, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 28),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      width: 390,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: _exitScreening,
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
                color: _primaryBlue,
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
    return WillPopScope(
      onWillPop: _handleSystemBack,
      child: Scaffold(
        backgroundColor: _bgColor,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Column(
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 14),
                        Text(
                          '${_controller.currentStep} of ${_controller.totalSteps}',
                          style: const TextStyle(
                            color: _textGray,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 34),
                        Text(
                          _controller.currentWord.displayWord,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _primaryBlue,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 78),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _controller.isRecording
                                ? 'Recording... please wait, it will stop automatically.'
                                : _controller.hasRecording
                                ? 'Would you like to record again or continue?'
                                : _controller.isPromptPlaying
                                ? 'Prompt is playing... please wait before recording.'
                                : 'Tap the speaker to hear the word, then tap the microphone to record.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _textGray,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        if (_controller.errorMessage != null) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            width: 390,
                            child: Text(
                              _controller.errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        if (!_controller.hasRecording)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _roundActionButton(
                                icon: Icons.volume_up_rounded,
                                onTap: _controller.canPlayPrompt
                                    ? _controller.playPromptAudio
                                    : null,
                                fillColor: _controller.isPromptPlaying
                                    ? _primaryBlue.withValues(alpha: 0.18)
                                    : _circleGray,
                                iconColor: _controller.isPromptPlaying
                                    ? _primaryBlue
                                    : (_controller.canPlayPrompt
                                          ? _iconGray
                                          : _disabledGray),
                              ),
                              const SizedBox(width: 22),
                              _roundActionButton(
                                icon: Icons.mic_rounded,
                                onTap: _controller.canRecord
                                    ? _controller.startTimedRecording
                                    : null,
                                fillColor: _controller.isRecording
                                    ? Colors.red.withValues(alpha: 0.16)
                                    : _circleGray,
                                iconColor: _controller.isRecording
                                    ? Colors.red
                                    : (_controller.canRecord
                                          ? _iconGray
                                          : _disabledGray),
                              ),
                            ],
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _roundActionButton(
                                icon: Icons.refresh_rounded,
                                onTap: _controller.isRecording
                                    ? null
                                    : _controller.repeatCurrentWord,
                                fillColor: _circleGray,
                                iconColor: _controller.isRecording
                                    ? _disabledGray
                                    : _iconGray,
                              ),
                              const SizedBox(width: 22),
                              _roundActionButton(
                                icon: Icons.arrow_forward_rounded,
                                onTap: _controller.isRecording
                                    ? null
                                    : _handleNext,
                                fillColor: _circleGray,
                                iconColor: _controller.isRecording
                                    ? _disabledGray
                                    : _iconGray,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
