import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/learning_module_model.dart';
import '../../../models/screening_word_model.dart';
import '../../../models/speech_profile_model.dart';
import '../../../services/dynamic_modules_service.dart';
import '../../../services/learning_module_store.dart';
import '../../../services/phoneme_assessment_service.dart';

class ScreeningResultsController extends ChangeNotifier {
  final List<ScreeningWordModel> words;
  final Map<String, String> recordingsByWordId;
  final Map<String, PhonemeAssessmentResult> assessmentResultsByWordId;
  final PhonemeAssessmentService _assessmentService;
  final DynamicModulesService? _modulesService;
  final AudioPlayer _player;
  final List<PhonemeAssessmentResult> _results = [];
  final Set<String> _failedWordIds = {};

  bool _isRunning = true;
  int _processedCount = 0;
  String? _playingWordId;
  int _playbackSession = 0;
  bool _disposed = false;
  LearningModuleModel? _learningModule;

  ScreeningResultsController({
    required this.words,
    required this.recordingsByWordId,
    required this.assessmentResultsByWordId,
    required PhonemeAssessmentService assessmentService,
    required AudioPlayer player,
    DynamicModulesService? modulesService,
  }) : _assessmentService = assessmentService,
       _modulesService = modulesService,
       _player = player;

  factory ScreeningResultsController.createDefault({
    required List<ScreeningWordModel> words,
    required Map<String, String> recordingsByWordId,
    required Map<String, PhonemeAssessmentResult> assessmentResultsByWordId,
  }) {
    return ScreeningResultsController(
      words: words,
      recordingsByWordId: recordingsByWordId,
      assessmentResultsByWordId: assessmentResultsByWordId,
      assessmentService: PhonemeAssessmentService(),
      player: AudioPlayer(),
      modulesService: DynamicModulesService(),
    );
  }

  List<PhonemeAssessmentResult> get results => List.unmodifiable(_results);
  bool get isRunning => _isRunning;
  int get processedCount => _processedCount;
  String? get playingWordId => _playingWordId;
  Set<String> get failedWordIds => Set.unmodifiable(_failedWordIds);

  /// The personalized practice module built from the detected processes
  /// (null until the module request completes — may stay null if the
  /// module service is unreachable or no processes were detected).
  LearningModuleModel? get learningModule => _learningModule;

  SpeechProfileModel buildSpeechProfile() {
    final validResults = _results.where((result) => result.isSuccess).toList();
    final processCounts = <String, int>{};
    final positionCounts = <String, int>{};

    for (final result in validResults) {
      for (final process in result.detectedProcesses) {
        final name = process['process']?.toString().trim() ?? '';
        final position = process['position']?.toString().trim() ?? '';
        if (name.isNotEmpty) {
          processCounts.update(name, (count) => count + 1, ifAbsent: () => 1);
        }
        if (position.isNotEmpty) {
          positionCounts.update(
            position,
            (count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }

    final rankedProcesses =
        processCounts.entries.where((entry) => entry.value >= 2).toList()
          ..sort((a, b) {
            final byEvidence = b.value.compareTo(a.value);
            return byEvidence != 0 ? byEvidence : a.key.compareTo(b.key);
          });
    final rankedPositions = positionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final moduleItems = _learningModule?.allItems ?? const [];
    final approvedWords = <String>{
      ...moduleItems.map((item) => item.text.trim().toUpperCase()),
      ...validResults.map((result) => result.displayWord.trim().toUpperCase()),
    }..removeWhere((word) => word.isEmpty);
    final targetPhonemes = <String>{
      ...?_learningModule?.focusSounds,
      ...moduleItems.map((item) => item.targetSound.trim()),
    }..removeWhere((sound) => sound.isEmpty);

    return SpeechProfileModel(
      primaryTarget: rankedProcesses.isEmpty ? '' : rankedProcesses.first.key,
      secondaryTarget: rankedProcesses.length < 2 ? '' : rankedProcesses[1].key,
      reviewTargets: rankedProcesses.skip(2).map((entry) => entry.key).toList(),
      targetPhonemes: targetPhonemes.toList(growable: false),
      wordPosition: rankedPositions.isEmpty ? '' : rankedPositions.first.key,
      approvedWords: approvedWords.toList(growable: false),
      averageAccuracy: _averageAccuracy,
      validAttempts: validResults.length,
      evidenceCounts: Map.fromEntries(rankedProcesses),
    );
  }

  Future<void> start() async {
    debugPrint(
      '[screening-api] run_start words=${words.length} '
      'recordings=${recordingsByWordId.length} '
      'precomputed_results=${assessmentResultsByWordId.length} '
      'base_url=${_assessmentService.baseUrl}',
    );

    for (final word in words) {
      if (_disposed) return;

      final recordingPath = recordingsByWordId[word.id];
      final precomputedResult = assessmentResultsByWordId[word.id];
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
        );
      }

      _logDetectedProcesses(result);
      if (_disposed) return;

      _results.add(result);
      _processedCount++;
      if (!result.isSuccess) {
        _failedWordIds.add(word.id);
      } else {
        _failedWordIds.remove(word.id);
      }
      notifyListeners();
    }

    final filePath = await _writeTemporaryResultsFile();
    debugPrint(
      '[screening-api] run_complete processed=$_processedCount '
      'detected_processes=${_detectedProcessesForPayload.length} '
      'result_file=$filePath',
    );
    if (_disposed) return;

    await _requestLearningModule();

    _isRunning = false;
    notifyListeners();
  }

  /// Builds the personalized practice module from the child's age and all
  /// detected processes (dynamic modules service, port 8002).
  Future<void> _requestLearningModule() async {
    final modulesService = _modulesService;
    if (modulesService == null || words.isEmpty) return;

    final processes = _results
        .expand((result) => result.detectedProcesses)
        .map(
          (process) => {
            'process': process['process']?.toString() ?? '',
            'position': process['position']?.toString() ?? '',
            'detail': process['detail']?.toString() ?? '',
          },
        )
        .toList();

    if (processes.isEmpty) {
      debugPrint('[modules-api] module_skipped no_detected_processes');
      return;
    }

    // Persist the request inputs first — gameplay can RETRY the fetch
    // when the module service is unavailable right now.
    await LearningModuleStore().saveFindings(
      age: words.first.age,
      processes: processes,
    );

    try {
      _learningModule = await modulesService.buildModule(
        age: words.first.age,
        processes: processes,
      );
      debugPrint(
        '[modules-api] module_ready focus=${_learningModule?.focusSounds} '
        'levels=${_learningModule?.levels.length}',
      );
      if (_learningModule != null) {
        await LearningModuleStore().save(_learningModule!);
      }
    } on ModuleRequestException catch (error) {
      debugPrint('[modules-api] module_error message=${error.message}');
    } catch (error) {
      debugPrint('[modules-api] module_error unexpected=$error');
    }
  }

  Future<void> playRecording(PhonemeAssessmentResult result) async {
    final path = result.recordingPath;
    if (path.isEmpty) return;

    final file = File(path);
    if (!await file.exists()) return;

    final session = ++_playbackSession;
    _playingWordId = result.wordId;
    notifyListeners();

    try {
      await _player.stop();
      final completion = _player.onPlayerComplete.first;
      await _player.play(DeviceFileSource(path));
      await completion.timeout(const Duration(seconds: 20));
    } catch (error) {
      debugPrint('[screening-results] play_recording_error=$error path=$path');
    } finally {
      if (!_disposed && session == _playbackSession) {
        _playingWordId = null;
        notifyListeners();
      }
    }
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

  /// Retry assessment for a specific word that previously failed.
  ///
  /// Re-assesses the word and replaces the failure result in-place.
  /// Returns `true` if the word was a known failure and a retry was attempted.
  Future<bool> retryWord(String wordId) async {
    final word = words.firstWhere(
      (w) => w.id == wordId,
      orElse: () => throw ArgumentError('Word $wordId not found in screening'),
    );
    final recordingPath = recordingsByWordId[wordId];
    if (recordingPath == null || recordingPath.isEmpty) {
      debugPrint(
        '[screening-api] retry_abort word_id=$wordId reason=no_recording',
      );
      return false;
    }

    debugPrint(
      '[screening-api] retry_start word=${word.displayWord} word_id=$wordId '
      'path=$recordingPath',
    );

    final result = await _assessmentService.assess(
      word: word,
      recordingPath: recordingPath,
    );

    _logDetectedProcesses(result);
    if (_disposed) return true;

    // Replace the old result in-place
    final index = _results.indexWhere((r) => r.wordId == wordId);
    if (index != -1) {
      _results[index] = result;
    } else {
      _results.add(result);
    }

    if (result.isSuccess) {
      _failedWordIds.remove(wordId);
    }
    notifyListeners();

    debugPrint(
      '[screening-api] retry_complete word_id=$wordId '
      'success=${result.isSuccess} score=${result.overallScore}',
    );
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _playbackSession++;
    unawaited(_player.dispose());
    super.dispose();
  }
}
