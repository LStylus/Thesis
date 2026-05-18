import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_colors.dart';
import '../../models/screening_word_model.dart';
import '../../services/audio_recording_service.dart';
import '../../services/model_2_assessment_service.dart';

enum GameplayState {
  intro,
  asking,
  recording,
  assessing,
  correct,
  wrong,
  completed,
}

class GameplayScreen extends StatefulWidget {
  final String childProfileId;
  final String childName;
  final int childAge;
  final int levelIndex;

  const GameplayScreen({
    super.key,
    required this.childProfileId,
    required this.childName,
    required this.childAge,
    required this.levelIndex,
  });

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  final AudioRecordingService _recordingService = AudioRecordingService();
  final Model2AssessmentService _assessmentService = Model2AssessmentService();
  late final List<ScreeningWordModel> _words;

  GameplayState _state = GameplayState.intro;
  int _wordIndex = 0;
  int? _lastAccuracy;
  Model2AssessmentResult? _lastAssessment;
  String? _errorMessage;
  Timer? _promptTimer;

  static const double _passingScore = 80;

  ScreeningWordModel get _currentWord => _words[_wordIndex];
  bool get _isResultState =>
      _state == GameplayState.correct || _state == GameplayState.wrong;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _words = ScreeningWordModel.resolveForAge(widget.childAge).take(4).toList();
    _wordIndex = widget.levelIndex.clamp(0, _words.length - 1).toInt();
    _promptTimer = Timer(const Duration(milliseconds: 900), _askCurrentWord);
  }

  @override
  void dispose() {
    _promptTimer?.cancel();
    _recordingService.dispose();
    super.dispose();
  }

  void _askCurrentWord() {
    if (!mounted || _state == GameplayState.completed) return;

    _promptTimer?.cancel();
    setState(() {
      _state = GameplayState.asking;
      _lastAccuracy = null;
      _lastAssessment = null;
      _errorMessage = null;
    });

    _promptTimer = Timer(const Duration(milliseconds: 1500), _startRecording);
  }

  Future<void> _startRecording() async {
    if (!mounted || _state == GameplayState.completed) return;

    setState(() {
      _state = GameplayState.recording;
      _lastAssessment = null;
      _errorMessage = null;
    });

    final word = _currentWord;
    final recordingPath = await _recordingService.recordTimed(
      fileNamePrefix: '${widget.childProfileId}_${word.id}',
    );

    if (!mounted || _state != GameplayState.recording) return;

    if (recordingPath == null) {
      setState(() {
        _state = GameplayState.wrong;
        _lastAccuracy = 0;
        _errorMessage = 'No valid WAV recording was captured.';
      });
      return;
    }

    setState(() {
      _state = GameplayState.assessing;
    });

    final result = await _assessmentService.assess(
      word: word,
      recordingPath: recordingPath,
    );

    if (!mounted || _state != GameplayState.assessing) return;

    if (result.isSuccess) {
      final score = result.overallScore!.clamp(0, 100).toDouble();
      final passed = score >= _passingScore;
      setState(() {
        _state = passed ? GameplayState.correct : GameplayState.wrong;
        _lastAccuracy = score.round();
        _lastAssessment = result;
        _errorMessage = passed ? null : 'Let us try that word again.';
      });
    } else {
      setState(() {
        _state = GameplayState.wrong;
        _lastAccuracy = 0;
        _lastAssessment = result;
        _errorMessage = result.error ?? 'Model assessment failed.';
      });
    }
  }

  void _continueFromResult() {
    if (!mounted) return;

    if (_state == GameplayState.wrong) {
      _askCurrentWord();
      return;
    }

    _promptTimer?.cancel();
    Navigator.of(context).pop(
      GameplayLevelResult(
        levelIndex: _wordIndex,
        correct: true,
        accuracy: _lastAccuracy ?? 100,
      ),
    );
  }

  String get _bubbleText {
    switch (_state) {
      case GameplayState.intro:
        return widget.childName.trim().isEmpty
            ? 'Get ready for Island 1.'
            : 'Get ready, ${widget.childName}.';
      case GameplayState.asking:
      case GameplayState.recording:
        return 'Can you say ${_currentWord.displayWord}?';
      case GameplayState.assessing:
        return 'Checking ${_currentWord.displayWord}...';
      case GameplayState.correct:
        return 'Great saying!';
      case GameplayState.wrong:
        return 'Oops, let us try again.';
      case GameplayState.completed:
        return 'Great job! Island 1 complete!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _recordingService.cancel();
        }
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final bubbleTop = safePadding.top + 82.0;
            final resultPanelTop = (constraints.maxHeight - 318) / 2;

            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/backgrounds/ocean_classroom.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.06),
                          Colors.black.withValues(alpha: 0.02),
                          Colors.black.withValues(alpha: 0.12),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: safePadding.top + 12,
                  left: 12,
                  child: _CircleIconButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () async {
                      await _recordingService.cancel();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                Positioned(
                  top: safePadding.top + 18,
                  right: 18,
                  child: _ProgressPill(
                    text:
                        'Level ${(_wordIndex + 1).clamp(1, _words.length)} / ${_words.length}',
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  top: bubbleTop,
                  child: Center(child: _SpeechBubble(text: _bubbleText)),
                ),
                if (_state == GameplayState.recording)
                  Positioned(
                    left: 18,
                    right: 18,
                    top: bubbleTop + 82,
                    child: const Center(child: _RecordingStatus()),
                  ),
                if (_state == GameplayState.assessing)
                  Positioned(
                    left: 18,
                    right: 18,
                    top: bubbleTop + 82,
                    child: const Center(child: _AssessingStatus()),
                  ),
                if (_errorMessage != null && !_isResultState)
                  Positioned(
                    left: 18,
                    right: 18,
                    top: bubbleTop + 82,
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isResultState && _lastAccuracy != null)
                  Positioned(
                    top: resultPanelTop.clamp(safePadding.top + 118, 240),
                    left: 18,
                    right: 18,
                    child: Center(
                      child: _ResultPanel(
                        level: _wordIndex + 1,
                        totalLevels: _words.length,
                        word: _currentWord.displayWord,
                        correct: _state == GameplayState.correct,
                        accuracy: _lastAccuracy!,
                        assessment: _lastAssessment,
                        errorMessage: _errorMessage,
                        buttonText: _state == GameplayState.correct
                            ? 'Back to Map'
                            : 'Try Again',
                        onContinue: _continueFromResult,
                      ),
                    ),
                  ),
                if (_state == GameplayState.completed)
                  Positioned(
                    left: 18,
                    right: 18,
                    top: bubbleTop + 92,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
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
    );
  }
}

class GameplayLevelResult {
  final int levelIndex;
  final bool correct;
  final int accuracy;

  const GameplayLevelResult({
    required this.levelIndex,
    required this.correct,
    required this.accuracy,
  });
}

class _ResultPanel extends StatelessWidget {
  final int level;
  final int totalLevels;
  final String word;
  final bool correct;
  final int accuracy;
  final Model2AssessmentResult? assessment;
  final String? errorMessage;
  final String buttonText;
  final VoidCallback onContinue;

  const _ResultPanel({
    required this.level,
    required this.totalLevels,
    required this.word,
    required this.correct,
    required this.accuracy,
    required this.assessment,
    required this.errorMessage,
    required this.buttonText,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final modelScore = assessment?.overallScore?.clamp(0, 100).toDouble();
    final displayedScore = modelScore ?? accuracy.toDouble();
    final resultColor = correct ? const Color(0xFF18A85A) : AppColors.error;
    final expectedIpa = assessment?.expectedIpa;
    final detectedIpa = assessment?.detectedIpa;
    final processSummary = _processSummary(assessment);

    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Level $level of $totalLevels',
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            correct ? 'Correct!' : 'Try again',
            style: TextStyle(
              color: resultColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            word,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF3F5F73),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'Overall Score',
                style: TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${displayedScore.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: resultColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 9,
              value: displayedScore / 100,
              backgroundColor: const Color(0xFFE9F6FB),
              color: resultColor,
            ),
          ),
          if (assessment != null && assessment!.isSuccess) ...[
            const SizedBox(height: 12),
            _ModelOutputRow(label: 'Expected IPA', value: expectedIpa ?? '-'),
            const SizedBox(height: 5),
            _ModelOutputRow(label: 'Detected IPA', value: detectedIpa ?? '-'),
            if (processSummary != null) ...[
              const SizedBox(height: 5),
              _ModelOutputRow(label: 'Process', value: processSummary),
            ],
          ] else if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _processSummary(Model2AssessmentResult? result) {
    final processes = result?.assessment?['detected_processes'];
    if (processes is! List || processes.isEmpty) return null;

    final labels = processes.take(2).map((process) {
      if (process is! Map) return process.toString();
      final name = process['process']?.toString();
      final position = process['position']?.toString();
      if (name == null || name.isEmpty) return process.toString();
      if (position == null || position.isEmpty) return name;
      return '$name ($position)';
    }).toList();

    return labels.join(', ');
  }
}

class _ModelOutputRow extends StatelessWidget {
  final String label;
  final String value;

  const _ModelOutputRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF3F5F73),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  final String text;

  const _SpeechBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF3F5F73),
          fontSize: 19,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RecordingStatus extends StatelessWidget {
  const _RecordingStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic_rounded, size: 17, color: AppColors.primary),
          SizedBox(width: 7),
          Text(
            'Listening... 5 seconds',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessingStatus extends StatelessWidget {
  const _AssessingStatus();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Checking pronunciation...',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPill extends StatelessWidget {
  final String text;

  const _ProgressPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF3F5F73),
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      shape: const CircleBorder(),
      elevation: 5,
      shadowColor: Colors.black.withValues(alpha: 0.14),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: const Color(0xFF3F5F73), size: 24),
        ),
      ),
    );
  }
}
