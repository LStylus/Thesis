import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/screening_word_model.dart';
import '../../services/model_2_assessment_service.dart';
import '../auth/auth_gate.dart';

class ScreeningAccuracyResultsPage extends StatefulWidget {
  final List<ScreeningWordModel> words;
  final Map<String, String> recordingsByWordId;
  final Map<String, Model2AssessmentResult> assessmentResultsByWordId;

  const ScreeningAccuracyResultsPage({
    super.key,
    required this.words,
    required this.recordingsByWordId,
    required this.assessmentResultsByWordId,
  });

  @override
  State<ScreeningAccuracyResultsPage> createState() =>
      _ScreeningAccuracyResultsPageState();
}

class _ScreeningAccuracyResultsPageState
    extends State<ScreeningAccuracyResultsPage> {
  final Model2AssessmentService _assessmentService = Model2AssessmentService();
  final List<Model2AssessmentResult> _results = [];

  bool _isRunning = true;
  int _processedCount = 0;
  String? _resultsFilePath;

  @override
  void initState() {
    super.initState();
    _runAssessments();
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
      _resultsFilePath = filePath;
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
    return _results
        .expand((result) {
          return result.detectedProcesses.map((process) {
            return {
              'word_id': result.wordId,
              'display_word': result.displayWord,
              ...process,
            };
          });
        })
        .toList();
  }

  List<String> get _detectedProcessNames {
    final names = <String>{};
    for (final result in _results) {
      for (final process in result.detectedProcesses) {
        final name = process['process']?.toString();
        if (name != null && name.isNotEmpty) {
          names.add(name);
        }
      }
    }
    return names.toList();
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
      debugPrint(
        '$prefix process=$name position=$position detail=$detail',
      );
    }
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final detectedProcessNames = _detectedProcessNames;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isRunning
                        ? 'Checking pronunciation...'
                        : 'Screening Results',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Detected phonological processes from the screening API',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isRunning) ...[
                    LinearProgressIndicator(
                      value: widget.words.isEmpty
                          ? null
                          : _processedCount / widget.words.length,
                      color: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Processed $_processedCount / ${widget.words.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ] else ...[
                    _DetectedProcessSummaryCard(
                      processNames: detectedProcessNames,
                    ),
                    if (_resultsFilePath != null) ...[
                      const SizedBox(height: 12),
                      _TemporaryFileCard(path: _resultsFilePath!),
                    ],
                  ],
                  const SizedBox(height: 18),
                  ..._results.map((result) => _ResultCard(result: result)),
                  if (!_isRunning) ...[
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _goHome,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Continue to Home',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetectedProcessSummaryCard extends StatelessWidget {
  final List<String> processNames;

  const _DetectedProcessSummaryCard({required this.processNames});

  @override
  Widget build(BuildContext context) {
    final text = processNames.isEmpty
        ? 'No detected phonological process returned yet'
        : 'Detected: ${processNames.join(', ')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFBFF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _TemporaryFileCard extends StatelessWidget {
  final String path;

  const _TemporaryFileCard({required this.path});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Temporary result file',
            style: TextStyle(
              color: Color(0xFF4B4B4B),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            path,
            style: const TextStyle(
              color: AppColors.textGray,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Model2AssessmentResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final score = result.overallScore;
    final isSuccess = result.isSuccess;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  result.displayWord,
                  style: const TextStyle(
                    color: Color(0xFF4B4B4B),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                isSuccess ? '${score!.toStringAsFixed(1)}%' : 'Error',
                style: TextStyle(
                  color: isSuccess ? const Color(0xFF18A85A) : AppColors.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isSuccess) ...[
            LinearProgressIndicator(
              value: (score! / 100).clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFF18A85A),
              backgroundColor: const Color(0xFFEAF8F0),
            ),
            const SizedBox(height: 8),
            Text(
              'Expected: ${result.expectedIpa ?? '-'}   Detected: ${result.detectedIpa ?? '-'}',
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Process: ${result.detectedProcessSummary}',
              style: const TextStyle(
                color: Color(0xFF3F5F73),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ] else
            Text(
              result.error ?? 'Unknown model error.',
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}
