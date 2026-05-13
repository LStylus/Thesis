import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/screening_word_model.dart';
import '../../services/model_2_assessment_service.dart';
import '../auth/auth_gate.dart';

class ScreeningAccuracyResultsPage extends StatefulWidget {
  final List<ScreeningWordModel> words;
  final Map<String, String> recordingsByWordId;

  const ScreeningAccuracyResultsPage({
    super.key,
    required this.words,
    required this.recordingsByWordId,
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
    for (final word in widget.words) {
      final recordingPath = widget.recordingsByWordId[word.id];
      final result = recordingPath == null
          ? Model2AssessmentResult.failure(
              word: word,
              recordingPath: '',
              error: 'No recording was captured for this word.',
            )
          : await _assessmentService.assess(
              word: word,
              recordingPath: recordingPath,
            );

      if (!mounted) return;
      setState(() {
        _results.add(result);
        _processedCount++;
      });
    }

    final filePath = await _writeTemporaryResultsFile();
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

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final averageAccuracy = _averageAccuracy;

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
                    'Model-2 accuracy after signup screening',
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
                    _AverageAccuracyCard(averageAccuracy: averageAccuracy),
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

class _AverageAccuracyCard extends StatelessWidget {
  final double? averageAccuracy;

  const _AverageAccuracyCard({required this.averageAccuracy});

  @override
  Widget build(BuildContext context) {
    final text = averageAccuracy == null
        ? 'No successful model results yet'
        : '${averageAccuracy!.toStringAsFixed(1)}% average accuracy';

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
