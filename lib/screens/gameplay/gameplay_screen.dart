import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../models/screening_word_model.dart';
import '../../services/audio_recording_service.dart';
import '../../services/model_2_assessment_service.dart';
import '../../widgets/countdown_mic_button.dart';

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

class _GameplayScreenState extends State<GameplayScreen>
    with SingleTickerProviderStateMixin {
  final AudioRecordingService _recordingService = AudioRecordingService();
  final Model2AssessmentService _assessmentService = Model2AssessmentService();
  final AudioPlayer _promptPlayer = AudioPlayer();

  late final AnimationController _completionAnimationController;
  late final List<ScreeningWordModel> _words;
  late final List<_LevelOneWord> _levelOneWords;

  GameplayState _state = GameplayState.intro;
  int _wordIndex = 0;
  int? _lastAccuracy;
  Model2AssessmentResult? _lastAssessment;
  String? _errorMessage;
  Timer? _promptTimer;
  Timer? _levelOneCountdownTimer;
  Timer? _levelOneAutoRecordTimer;

  String? _selectedLevelOneWordId;
  final Set<String> _completedLevelOneWordIds = {};
  final Map<String, int> _levelOneWordAccuracies = {};
  bool _isLevelOnePlayingAudio = false;
  bool _isLevelOneRecording = false;
  bool _isLevelOneAssessing = false;
  bool _isLevelOneRecordPending = false;
  bool _showLevelOneCompletion = false;
  int _levelOneCountdown = _levelOneRecordingDuration.inSeconds;
  double _levelOneRecordProgress = 0;
  String? _levelOneErrorMessage;
  int _levelOneAudioToken = 0;
  int _genericPromptToken = 0;

  static const double _passingScore = 80;
  static const Duration _levelOneRecordingDuration = Duration(seconds: 3);
  static const Duration _levelOneAutoRecordDelay = Duration(seconds: 1);
  static const Duration _levelOneAudioTimeout = Duration(seconds: 10);
  static const Duration _feedbackAudioTimeout = Duration(seconds: 12);
  static const Duration _instructionAudioTimeout = Duration(seconds: 18);
  static const double _levelOneInactiveOpacity = 0.36;
  static const Duration _levelOneWordAnimationDuration =
      Duration(milliseconds: 260);

  ScreeningWordModel get _currentWord => _words[_wordIndex];
  bool get _isResultState =>
      _state == GameplayState.correct || _state == GameplayState.wrong;
  bool get _usesWordPairGameplay =>
      widget.levelIndex >= 0 && widget.levelIndex <= 2;
  String get _wordPairProgressText => '1/4';
  _LevelOneWord? get _selectedLevelOneWord {
    final selectedId = _selectedLevelOneWordId;
    if (selectedId == null) return null;

    for (final word in _levelOneWords) {
      if (word.id == selectedId) return word;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _completionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _levelOneWords = _wordPairForLevel(widget.levelIndex);

    if (_usesWordPairGameplay) {
      _words = _levelOneWords.map((word) => word.model).toList();
      _state = GameplayState.asking;
      _promptTimer = Timer(const Duration(milliseconds: 550), () {
        unawaited(_playLevelOneIntroInstruction());
      });
      return;
    }

    _words = ScreeningWordModel.resolveForAge(widget.childAge).take(4).toList();
    _wordIndex = widget.levelIndex.clamp(0, _words.length - 1).toInt();
    _promptTimer = Timer(const Duration(milliseconds: 900), _askCurrentWord);
  }

  List<_LevelOneWord> _wordPairForLevel(int levelIndex) {
    switch (levelIndex) {
      case 1:
        return [
          _LevelOneWord(
            model: ScreeningWordModel.age4Words[7],
            imageAssetPath: 'assets/props/dog.svg',
            audioAssetPath: AppAssets.gameplayWordAudio('dog'),
          ),
          _LevelOneWord(
            model: ScreeningWordModel.age4Words[6],
            imageAssetPath: 'assets/props/10.svg',
            audioAssetPath: AppAssets.gameplayWordAudio('ten'),
          ),
        ];
      case 2:
        return [
          _LevelOneWord(
            model: ScreeningWordModel.age4Words[12],
            imageAssetPath: 'assets/props/key.svg',
            audioAssetPath: AppAssets.gameplayWordAudio('key'),
          ),
          _LevelOneWord(
            model: ScreeningWordModel.age4Words[13],
            imageAssetPath: 'assets/props/goat.svg',
            audioAssetPath: AppAssets.gameplayWordAudio('goat'),
          ),
        ];
      case 0:
      default:
        return [
          _LevelOneWord(
            model: ScreeningWordModel.age4Words[0],
            imageAssetPath: 'assets/props/pig.svg',
            audioAssetPath: AppAssets.gameplayWordAudio('pig'),
          ),
          _LevelOneWord(
            model: ScreeningWordModel.age4Words[1],
            imageAssetPath: 'assets/props/ball.svg',
            audioAssetPath: AppAssets.gameplayWordAudio('ball'),
          ),
        ];
    }
  }

  @override
  void dispose() {
    _promptTimer?.cancel();
    _levelOneCountdownTimer?.cancel();
    _levelOneAutoRecordTimer?.cancel();
    _completionAnimationController.dispose();
    unawaited(_promptPlayer.dispose());
    _recordingService.dispose();
    super.dispose();
  }

  void _askCurrentWord() {
    if (!mounted || _state == GameplayState.completed) return;

    _promptTimer?.cancel();
    _genericPromptToken++;
    setState(() {
      _state = GameplayState.asking;
      _lastAccuracy = null;
      _lastAssessment = null;
      _errorMessage = null;
    });

    if (widget.levelIndex >= 3) {
      unawaited(_playFinalInstructionThenRecord(_genericPromptToken));
      return;
    }

    _promptTimer = Timer(const Duration(milliseconds: 1500), _startRecording);
  }

  Future<void> _playFinalInstructionThenRecord(int token) async {
    await _playAudioAsset(
      AppAssets.finalLevelInstructionAudio,
      timeout: _instructionAudioTimeout,
    );
    await Future<void>.delayed(_levelOneAutoRecordDelay);

    if (!mounted ||
        token != _genericPromptToken ||
        _state != GameplayState.asking) {
      return;
    }

    await _startRecording();
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
      duration: _levelOneRecordingDuration,
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
      final feedback = _feedbackForScore(score.round());
      final passed = score >= _passingScore;
      setState(() {
        _state = passed ? GameplayState.correct : GameplayState.wrong;
        _lastAccuracy = score.round();
        _lastAssessment = result;
        _errorMessage = passed ? null : feedback.message;
      });

      if (!passed && widget.levelIndex >= 3) {
        await _playGenericRetryFeedback(feedback);
        return;
      }

      if (passed && widget.levelIndex >= 3) {
        unawaited(
          _playAudioAsset(
            feedback.audioAssetPath,
            timeout: _feedbackAudioTimeout,
          ),
        );
      }
    } else {
      setState(() {
        _state = GameplayState.wrong;
        _lastAccuracy = 0;
        _lastAssessment = result;
        _errorMessage = result.error ?? 'Model assessment failed.';
      });
    }
  }

  Future<void> _playGenericRetryFeedback(_AccuracyFeedback feedback) async {
    final token = ++_genericPromptToken;

    await _playAudioAsset(
      feedback.audioAssetPath,
      timeout: _feedbackAudioTimeout,
    );

    if (!mounted || token != _genericPromptToken) return;
    _askCurrentWord();
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

  Future<void> _playAudioAsset(
    String assetPath, {
    Duration timeout = _levelOneAudioTimeout,
  }) async {
    StreamSubscription<void>? completeSubscription;
    final completed = Completer<void>();

    try {
      await _promptPlayer.stop();
      completeSubscription = _promptPlayer.onPlayerComplete.listen((_) {
        if (!completed.isCompleted) completed.complete();
      });
      await _promptPlayer.play(AssetSource(assetPath));
      await completed.future.timeout(
        timeout,
        onTimeout: () {},
      );
    } catch (error) {
      debugPrint('[gameplay-audio] unavailable asset=$assetPath error=$error');
    } finally {
      await completeSubscription?.cancel();
    }
  }

  Future<void> _playLevelOneIntroInstruction() async {
    if (!mounted ||
        !_usesWordPairGameplay ||
        _selectedLevelOneWordId != null ||
        _showLevelOneCompletion) {
      return;
    }

    await _playAudioAsset(
      AppAssets.levelOneThreeInstructionAudio,
      timeout: _instructionAudioTimeout,
    );
  }

  _AccuracyFeedback _feedbackForScore(int score) {
    final boundedScore = score.clamp(0, 100);

    if (boundedScore < 50) {
      return const _AccuracyFeedback(
        message: 'Not quite right.',
        audioAssetPath: AppAssets.quiteNotRightAudio,
      );
    }

    if (boundedScore < _passingScore) {
      return const _AccuracyFeedback(
        message: 'Almost there. Say it again.',
        audioAssetPath: AppAssets.almostThereAudio,
      );
    }

    if (boundedScore < 95) {
      return const _AccuracyFeedback(
        message: "You're doing great!",
        audioAssetPath: AppAssets.youreDoingGreatAudio,
      );
    }

    return const _AccuracyFeedback(
      message: 'Good job!',
      audioAssetPath: AppAssets.goodJobAudio,
    );
  }

  Future<void> _selectLevelOneWord(_LevelOneWord word) async {
    if (_completedLevelOneWordIds.contains(word.id) ||
        _isLevelOneRecording ||
        _isLevelOneAssessing ||
        _isLevelOnePlayingAudio) {
      return;
    }

    if (_selectedLevelOneWordId == word.id) {
      await _replaySelectedLevelOneWord();
      return;
    }

    if (_selectedLevelOneWordId != null) return;

    _levelOneAutoRecordTimer?.cancel();
    setState(() {
      _selectedLevelOneWordId = word.id;
      _isLevelOnePlayingAudio = true;
      _isLevelOneRecordPending = false;
      _levelOneErrorMessage = null;
    });

    await _playLevelOnePronunciation(word, ++_levelOneAudioToken);
  }

  Future<void> _replaySelectedLevelOneWord() async {
    final selectedWord = _selectedLevelOneWord;
    if (selectedWord == null ||
        _isLevelOnePlayingAudio ||
        _isLevelOneRecording ||
        _isLevelOneAssessing) {
      return;
    }

    _levelOneAutoRecordTimer?.cancel();
    setState(() {
      _isLevelOnePlayingAudio = true;
      _isLevelOneRecordPending = false;
      _levelOneErrorMessage = null;
    });

    await _playLevelOnePronunciation(selectedWord, ++_levelOneAudioToken);
  }

  Future<void> _playLevelOnePronunciation(
    _LevelOneWord word,
    int audioToken,
  ) async {
    await _playAudioAsset(word.audioAssetPath);

    if (!mounted ||
        _selectedLevelOneWordId != word.id ||
        audioToken != _levelOneAudioToken) {
      return;
    }

    setState(() {
      _isLevelOnePlayingAudio = false;
      _isLevelOneRecordPending = true;
    });
    _queueLevelOneAutoRecord(word, audioToken);
  }

  void _queueLevelOneAutoRecord(_LevelOneWord word, int audioToken) {
    _levelOneAutoRecordTimer?.cancel();
    _levelOneAutoRecordTimer = Timer(_levelOneAutoRecordDelay, () {
      if (!mounted ||
          _selectedLevelOneWordId != word.id ||
          audioToken != _levelOneAudioToken ||
          _isLevelOneRecording ||
          _isLevelOneAssessing ||
          _showLevelOneCompletion) {
        return;
      }

      unawaited(_recordSelectedLevelOneWord());
    });
  }

  Future<void> _recordSelectedLevelOneWord() async {
    final selectedWord = _selectedLevelOneWord;
    if (selectedWord == null ||
        !_isLevelOneRecordPending ||
        _isLevelOnePlayingAudio ||
        _isLevelOneRecording ||
        _isLevelOneAssessing) {
      return;
    }

    setState(() {
      _isLevelOneRecording = true;
      _isLevelOneAssessing = false;
      _isLevelOneRecordPending = false;
      _levelOneCountdown = _levelOneRecordingDuration.inSeconds;
      _levelOneRecordProgress = 0;
      _levelOneErrorMessage = null;
    });

    _levelOneCountdownTimer?.cancel();
    final recordingStartedAt = DateTime.now();
    _levelOneCountdownTimer = Timer.periodic(const Duration(milliseconds: 50), (
      timer,
    ) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(recordingStartedAt);
      final progress =
          elapsed.inMilliseconds / _levelOneRecordingDuration.inMilliseconds;
      final remaining = _levelOneRecordingDuration - elapsed;
      setState(() {
        _levelOneRecordProgress = progress.clamp(0, 1).toDouble();
        _levelOneCountdown = remaining.inMilliseconds <= 0
            ? 0
            : (remaining.inMilliseconds / 1000).ceil();
      });
    });

    final recordingPath = await _recordingService.recordTimed(
      fileNamePrefix: '${widget.childProfileId}_${selectedWord.model.id}',
      duration: _levelOneRecordingDuration,
    );

    _levelOneCountdownTimer?.cancel();

    if (!mounted || _selectedLevelOneWordId != selectedWord.id) return;

    if (recordingPath == null) {
      setState(() {
        _isLevelOneRecording = false;
        _isLevelOneAssessing = false;
        _isLevelOneRecordPending = true;
        _levelOneCountdown = _levelOneRecordingDuration.inSeconds;
        _levelOneRecordProgress = 0;
        _levelOneErrorMessage = 'No valid WAV recording was captured.';
      });
      _queueLevelOneAutoRecord(selectedWord, ++_levelOneAudioToken);
      return;
    }

    setState(() {
      _isLevelOneRecording = false;
      _isLevelOneAssessing = true;
      _levelOneCountdown = _levelOneRecordingDuration.inSeconds;
      _levelOneRecordProgress = 1;
    });

    final assessment = await _assessmentService.assess(
      word: selectedWord.model,
      recordingPath: recordingPath,
    );

    if (!mounted || _selectedLevelOneWordId != selectedWord.id) return;

    var selectedAccuracy = 100;
    if (assessment.isSuccess) {
      final score = assessment.overallScore!.clamp(0, 100).toDouble();
      if (score < _passingScore) {
        await _playLevelOneRetryFeedback(selectedWord, score.round());
        return;
      }
      selectedAccuracy = score.round();
    } else {
      debugPrint(
        '[level-one] assessment unavailable for ${selectedWord.label}: '
        '${assessment.error}',
      );
    }

    final completedWordIds = {
      ..._completedLevelOneWordIds,
      selectedWord.id,
    };
    final levelComplete = completedWordIds.length == _levelOneWords.length;

    setState(() {
      _completedLevelOneWordIds
        ..clear()
        ..addAll(completedWordIds);
      _levelOneWordAccuracies[selectedWord.id] = selectedAccuracy;
      _selectedLevelOneWordId = null;
      _isLevelOneRecording = false;
      _isLevelOneAssessing = false;
      _isLevelOneRecordPending = false;
      _levelOneCountdown = _levelOneRecordingDuration.inSeconds;
      _levelOneRecordProgress = 0;
      _levelOneErrorMessage = null;
      _showLevelOneCompletion = levelComplete;
      if (levelComplete) {
        _state = GameplayState.completed;
      }
    });

    if (levelComplete) {
      _completionAnimationController.repeat(reverse: true);
      unawaited(
        _playAudioAsset(
          AppAssets.goodJobAudio,
          timeout: _feedbackAudioTimeout,
        ),
      );
    } else {
      final successFeedback = _feedbackForScore(selectedAccuracy);
      unawaited(
        _playAudioAsset(
          successFeedback.audioAssetPath,
          timeout: _feedbackAudioTimeout,
        ),
      );
    }
  }

  Future<void> _playLevelOneRetryFeedback(
    _LevelOneWord selectedWord,
    int score,
  ) async {
    final audioToken = ++_levelOneAudioToken;
    final feedback = _feedbackForScore(score);

    setState(() {
      _isLevelOneAssessing = false;
      _isLevelOnePlayingAudio = true;
      _isLevelOneRecordPending = false;
      _levelOneRecordProgress = 0;
      _levelOneErrorMessage = feedback.message;
    });

    await _playAudioAsset(
      feedback.audioAssetPath,
      timeout: _feedbackAudioTimeout,
    );

    if (!mounted ||
        _selectedLevelOneWordId != selectedWord.id ||
        audioToken != _levelOneAudioToken) {
      return;
    }

    setState(() {
      _isLevelOnePlayingAudio = false;
      _selectedLevelOneWordId = null;
      _isLevelOneRecordPending = false;
      _levelOneRecordProgress = 0;
    });
  }

  Future<void> _closeGameplay() async {
    _promptTimer?.cancel();
    _levelOneAutoRecordTimer?.cancel();
    await _recordingService.cancel();
    await _promptPlayer.stop();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _finishLevelOne() {
    final accuracies = _levelOneWordAccuracies.values.toList();
    final averageAccuracy = accuracies.isEmpty
        ? 100
        : (accuracies.reduce((left, right) => left + right) / accuracies.length)
              .round()
              .clamp(0, 100)
              .toInt();

    Navigator.of(context).pop(
      GameplayLevelResult(
        levelIndex: widget.levelIndex,
        correct: true,
        accuracy: averageAccuracy,
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
    if (_usesWordPairGameplay) {
      return _buildLevelOneGameplay(context);
    }

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
                    onTap: _closeGameplay,
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

  Widget _buildLevelOneGameplay(BuildContext context) {
    final safePadding = MediaQuery.paddingOf(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _recordingService.cancel();
          _promptPlayer.stop();
        }
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final boardWidth = (constraints.maxWidth * 0.54).clamp(
              340.0,
              530.0,
            );
            final boardHeight = (constraints.maxHeight * 0.52).clamp(
              205.0,
              285.0,
            );
            final boardYOffset = -constraints.maxHeight * 0.12;

            return Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/backgrounds/ocean_classroom.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                Positioned(
                  top: safePadding.top + 10,
                  left: 14,
                  child: _SquareIconButton(
                    icon: Icons.close_rounded,
                    onTap: _closeGameplay,
                  ),
                ),
                Positioned(
                  top: safePadding.top + 18,
                  right: 22,
                  child: Text(
                    _wordPairProgressText,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Center(
                  child: Transform.translate(
                    offset: Offset(0, boardYOffset),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      child: _showLevelOneCompletion
                          ? _LevelOneCompletionBoard(
                              key: const ValueKey('level-one-complete'),
                              width: boardWidth,
                              height: boardHeight,
                              animation: _completionAnimationController,
                              onNext: _finishLevelOne,
                            )
                          : _LevelOneWordBoard(
                              key: const ValueKey('level-one-words'),
                              width: boardWidth,
                              height: boardHeight,
                              words: _levelOneWords,
                              selectedWordId: _selectedLevelOneWordId,
                              completedWordIds: _completedLevelOneWordIds,
                              inactiveOpacity: _levelOneInactiveOpacity,
                              animationDuration: _levelOneWordAnimationDuration,
                              onWordTap: _selectLevelOneWord,
                            ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: safePadding.bottom + 14,
                  child: const _LevelOneNotice(),
                ),
                if (!_showLevelOneCompletion)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: safePadding.bottom + (compact ? 10 : 16),
                    child: Center(
                      child: RecordingMicButton(
                        isPending: _isLevelOneRecordPending,
                        isRecording: _isLevelOneRecording,
                        isProcessing: _isLevelOneAssessing,
                        countdown: _levelOneCountdown,
                        progress: _levelOneRecordProgress,
                        idleLabel: 'Record',
                        size: 58,
                      ),
                    ),
                  ),
                if (_levelOneErrorMessage != null && !_showLevelOneCompletion)
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: safePadding.bottom + 78,
                    child: Text(
                      _levelOneErrorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
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

class _AccuracyFeedback {
  final String message;
  final String audioAssetPath;

  const _AccuracyFeedback({
    required this.message,
    required this.audioAssetPath,
  });
}

class _LevelOneWord {
  final ScreeningWordModel model;
  final String imageAssetPath;
  final String audioAssetPath;

  const _LevelOneWord({
    required this.model,
    required this.imageAssetPath,
    required this.audioAssetPath,
  });

  String get id => model.id;
  String get label => model.displayWord;
}

class _LevelOneWordBoard extends StatelessWidget {
  final double width;
  final double height;
  final List<_LevelOneWord> words;
  final String? selectedWordId;
  final Set<String> completedWordIds;
  final double inactiveOpacity;
  final Duration animationDuration;
  final ValueChanged<_LevelOneWord> onWordTap;

  const _LevelOneWordBoard({
    super.key,
    required this.width,
    required this.height,
    required this.words,
    required this.selectedWordId,
    required this.completedWordIds,
    required this.inactiveOpacity,
    required this.animationDuration,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    return _ChalkboardFrame(
      width: width,
      height: height,
      child: Column(
        children: [
          const SizedBox(height: 14),
          const Text(
            'Tap on the image and speak',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final word in words) ...[
                _LevelOneWordCard(
                  word: word,
                  isSelected: selectedWordId == word.id,
                  isCompleted: completedWordIds.contains(word.id),
                  isDisabled: selectedWordId != null && selectedWordId != word.id,
                  inactiveOpacity: inactiveOpacity,
                  animationDuration: animationDuration,
                  onTap: () => onWordTap(word),
                ),
                if (word != words.last) SizedBox(width: width * 0.12),
              ],
            ],
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _LevelOneWordCard extends StatelessWidget {
  final _LevelOneWord word;
  final bool isSelected;
  final bool isCompleted;
  final bool isDisabled;
  final double inactiveOpacity;
  final Duration animationDuration;
  final VoidCallback onTap;

  const _LevelOneWordCard({
    required this.word,
    required this.isSelected,
    required this.isCompleted,
    required this.isDisabled,
    required this.inactiveOpacity,
    required this.animationDuration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = isCompleted || isDisabled ? inactiveOpacity : 1.0;
    final scale = isSelected ? 1.18 : 1.0;
    final canTap = !isCompleted && !isDisabled;

    return AnimatedOpacity(
      opacity: opacity,
      duration: animationDuration,
      child: AnimatedScale(
        scale: scale,
        duration: animationDuration,
        curve: Curves.easeOutBack,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: canTap ? onTap : null,
          child: SizedBox(
            width: 112,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 112,
                      child: SvgPicture.asset(
                        word.imageAssetPath,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
                if (isCompleted)
                  Positioned(
                    right: 9,
                    top: 3,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFF21B15F),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelOneCompletionBoard extends StatelessWidget {
  final double width;
  final double height;
  final Animation<double> animation;
  final VoidCallback onNext;

  const _LevelOneCompletionBoard({
    super.key,
    required this.width,
    required this.height,
    required this.animation,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        _ChalkboardFrame(
          width: width,
          height: height,
          child: AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final starScale = 1 + (animation.value * 0.1);

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: starScale,
                    child: const _CompletionStars(),
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - value)),
                          child: child,
                        ),
                      );
                    },
                    child: const Text(
                      'Good Job!',
                      style: TextStyle(
                        color: Color(0xFFFFD229),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Reward: 500',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Positioned(
          right: 18,
          bottom: -24,
          child: _NextGameplayButton(onTap: onNext),
        ),
      ],
    );
  }
}

class _CompletionStars extends StatelessWidget {
  const _CompletionStars();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 142,
      height: 78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 6,
            bottom: 12,
            child: Transform.rotate(
              angle: -0.18,
              child: SvgPicture.asset('assets/props/Star 1.svg', width: 42),
            ),
          ),
          SvgPicture.asset('assets/props/Star 1.svg', width: 72),
          Positioned(
            right: 6,
            bottom: 12,
            child: Transform.rotate(
              angle: 0.18,
              child: SvgPicture.asset('assets/props/Star 1.svg', width: 42),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextGameplayButton extends StatelessWidget {
  final VoidCallback onTap;

  const _NextGameplayButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SvgPicture.asset(
        'assets/icons/next_gameplay_button.svg',
        width: 106,
        height: 36,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _ChalkboardFrame extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;

  const _ChalkboardFrame({
    required this.width,
    required this.height,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7B4D32),
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF053C21),
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A4C2A), Color(0xFF022B18)],
              ),
            ),
            child: child,
          ),
        ),
        Positioned(
          bottom: -8,
          child: Container(
            width: width + 16,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5A37),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ],
    );
  }
}

class _LevelOneNotice extends StatelessWidget {
  const _LevelOneNotice();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NOTICE:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Please ensure your microphone is working and in a quiet environment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.08,
            ),
          ),
        ],
      ),
    );
  }
}

class _SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Close',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Icon(icon, color: const Color(0xFFCFCFCF), size: 20),
        ),
      ),
    );
  }
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
