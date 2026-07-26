import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../../models/screening_word_model.dart';
import '../../../services/model_2_assessment_service.dart';

class ScreeningResultsController extends ChangeNotifier {
  final List<ScreeningWordModel> words;
  final Map<String, String> recordingsByWordId;
  final Map<String, Model2AssessmentResult> assessmentResultsByWordId;
  final Model2AssessmentService _assessmentService;
  final AudioPlayer _player;
  final List<Model2AssessmentResult> _results = [];

  bool _isRunning = true;
  int _processedCount = 0;
  String? _playingWordId;
  int _playbackSession = 0;
  bool _disposed = false;

  ScreeningResultsController({
    required this.words,
    required this.recordingsByWordId,
    required this.assessmentResultsByWordId,
    required Model2AssessmentService assessmentService,
    required AudioPlayer player,
  }) : _assessmentService = assessmentService,
       _player = player;

  factory ScreeningResultsController.createDefault({
    required List<ScreeningWordModel> words,
    required Map<String, String> recordingsByWordId,
    required Map<String, Model2AssessmentResult> assessmentResultsByWordId,
  }) {
    return ScreeningResultsController(
      words: words,
      recordingsByWordId: recordingsByWordId,
      assessmentResultsByWordId: assessmentResultsByWordId,
      assessmentService: Model2AssessmentService(),
      player: AudioPlayer(),
    );
  }

  List<Model2AssessmentResult> get results => List.unmodifiable(_results);
  bool get isRunning => _isRunning;
  int get processedCount => _processedCount;
  String? get playingWordId => _playingWordId;

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

      final Model2AssessmentResult result;
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
        result = Model2AssessmentResult.failure(
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
      notifyListeners();
    }

    final filePath = await _writeTemporaryResultsFile();
    debugPrint(
      '[screening-api] run_complete processed=$_processedCount '
      'detected_processes=${_detectedProcessesForPayload.length} '
      'result_file=$filePath',
    );
    if (_disposed) return;

    _isRunning = false;
    notifyListeners();
  }

  Future<void> playRecording(Model2AssessmentResult result) async {
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

  void _logDetectedProcesses(Model2AssessmentResult result) {
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

  @override
  void dispose() {
    _disposed = true;
    _playbackSession++;
    unawaited(_player.dispose());
    super.dispose();
  }
}
