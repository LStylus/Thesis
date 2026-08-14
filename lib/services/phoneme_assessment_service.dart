import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/screening_word_model.dart';

class PhonemeAssessmentService {
  PhonemeAssessmentService({String? baseUrl})
    : baseUrl = baseUrl ?? _defaultBaseUrl;

  final String baseUrl;

  /// On Android emulator, 10.0.2.2 maps to the host machine's localhost.
  /// On other platforms (Windows, iOS simulator), localhost works directly.
  static String get _defaultBaseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:8001';
    return 'http://127.0.0.1:8001';
  }

  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(milliseconds: 500);

  Uri get _assessUri {
    return Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/assess');
  }

  Future<PhonemeAssessmentResult> assess({
    required ScreeningWordModel word,
    required String recordingPath,
  }) async {
    final requestStartedAt = DateTime.now();
    debugPrint(
      '[phoneme-api] assess_start word=${word.displayWord} '
      'word_id=${word.id} age=${word.age} base_url=$baseUrl uri=$_assessUri '
      'recording_path=$recordingPath',
    );

    final file = File(recordingPath);
    if (!await file.exists()) {
      debugPrint(
        '[phoneme-api] assess_abort word_id=${word.id} reason=file_not_found',
      );
      return PhonemeAssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: 'Recording file was not found.',
      );
    }

    return _withRetry(
      attempt: 0,
      word: word,
      recordingPath: recordingPath,
      file: file,
      requestStartedAt: requestStartedAt,
    );
  }

  Future<PhonemeAssessmentResult> _withRetry({
    required int attempt,
    required ScreeningWordModel word,
    required String recordingPath,
    required File file,
    required DateTime requestStartedAt,
  }) async {
    try {
      final fileSize = await file.length();
      debugPrint(
        '[phoneme-api] upload_prepare word_id=${word.id} '
        'attempt=${attempt + 1}/$_maxRetries '
        'filename=${_filenameFromPath(recordingPath)} bytes=$fileSize',
      );

      final request = http.MultipartRequest('POST', _assessUri)
        ..fields['word'] = word.displayWord.toLowerCase()
        ..fields['age'] = word.age.toString()
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            recordingPath,
            filename: _filenameFromPath(recordingPath),
            contentType: MediaType('audio', 'wav'),
          ),
        );

      debugPrint(
        '[phoneme-api] upload_send word_id=${word.id} '
        'field_word=${request.fields['word']} field_age=${request.fields['age']} '
        'file_field=file',
      );

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final elapsedMs = DateTime.now()
          .difference(requestStartedAt)
          .inMilliseconds;

      debugPrint(
        '[phoneme-api] response_received word_id=${word.id} '
        'status=${response.statusCode} elapsed_ms=$elapsedMs',
      );
      _logResponseBody(word.id, response.body);

      // Parse body first — model errors are in the body, not the HTTP status
      Map<String, dynamic>? decoded;
      try {
        if (response.body.isNotEmpty) {
          decoded = jsonDecode(response.body) as Map<String, dynamic>;
        }
      } catch (_) {
        // Invalid JSON — fall through to HTTP status check below
      }

      // Check for model-level or FastAPI validation error in the body
      // regardless of HTTP status
      if (decoded != null) {
        final bodyError = _extractBodyError(decoded);
        if (bodyError != null) {
          debugPrint(
            '[phoneme-api] response_error word_id=${word.id} '
            'message=$bodyError',
          );
          return PhonemeAssessmentResult.failure(
            word: word,
            recordingPath: recordingPath,
            error: bodyError,
            rawResponse: decoded,
          );
        }
      }

      // Retry on 5xx (server errors); pass through 4xx immediately
      if (response.statusCode >= 500 && response.statusCode < 600) {
        return _retryOrFail(
          attempt: attempt,
          word: word,
          recordingPath: recordingPath,
          file: file,
          requestStartedAt: requestStartedAt,
          error: 'Phoneme model returned HTTP ${response.statusCode}.',
          rawBody: response.body,
        );
      }

      // Fall back to HTTP status if no body error was found
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return PhonemeAssessmentResult.failure(
          word: word,
          recordingPath: recordingPath,
          error: 'Phoneme model returned HTTP ${response.statusCode}.',
          rawBody: response.body,
        );
      }

      // Must have a decoded body at this point for a successful response
      if (decoded == null) {
        return PhonemeAssessmentResult.failure(
          word: word,
          recordingPath: recordingPath,
          error: 'Phoneme model returned an empty response.',
        );
      }

      final success = PhonemeAssessmentResult.success(
        word: word,
        recordingPath: recordingPath,
        rawResponse: decoded,
      );
      debugPrint(
        '[phoneme-api] response_success word_id=${word.id} '
        'score=${success.overallScore} expected=${success.expectedIpa} '
        'detected=${success.detectedIpa} '
        'process_count=${success.detectedProcesses.length} '
        'processes=${success.detectedProcessSummary}',
      );
      return success;
    } on TimeoutException {
      return _retryOrFail(
        attempt: attempt,
        word: word,
        recordingPath: recordingPath,
        file: file,
        requestStartedAt: requestStartedAt,
        error: 'Phoneme model request timed out.',
      );
    } on SocketException {
      return _retryOrFail(
        attempt: attempt,
        word: word,
        recordingPath: recordingPath,
        file: file,
        requestStartedAt: requestStartedAt,
        error: 'Could not connect to the phoneme model at $baseUrl.',
      );
    } on FormatException {
      debugPrint('[phoneme-api] format_error word_id=${word.id}');
      return PhonemeAssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: 'Phoneme model returned an invalid response.',
      );
    } catch (error) {
      debugPrint(
        '[phoneme-api] unexpected_error word_id=${word.id} error=$error',
      );
      return PhonemeAssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: 'Phoneme model assessment failed: $error',
      );
    }
  }

  /// Retry with exponential backoff if attempts remain, or return failure.
  Future<PhonemeAssessmentResult> _retryOrFail({
    required int attempt,
    required ScreeningWordModel word,
    required String recordingPath,
    required File file,
    required DateTime requestStartedAt,
    required String error,
    String? rawBody,
  }) async {
    final nextAttempt = attempt + 1;
    if (nextAttempt >= _maxRetries) {
      debugPrint(
        '[phoneme-api] retry_exhausted word_id=${word.id} '
        'attempts=$nextAttempt/$_maxRetries error="$error"',
      );
      return PhonemeAssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: error,
        rawBody: rawBody,
      );
    }

    // Exponential backoff with jitter: baseDelay * 2^attempt + random(0..base)
    final delay =
        _baseDelay * pow(2, attempt).toInt() +
        Duration(milliseconds: Random().nextInt(_baseDelay.inMilliseconds));
    debugPrint(
      '[phoneme-api] retry_schedule word_id=${word.id} '
      'attempt=${nextAttempt + 1}/$_maxRetries delay_ms=${delay.inMilliseconds} '
      'error="$error"',
    );
    await Future<void>.delayed(delay);

    return _withRetry(
      attempt: nextAttempt,
      word: word,
      recordingPath: recordingPath,
      file: file,
      requestStartedAt: requestStartedAt,
    );
  }

  /// Extract a descriptive error from the response body.
  /// Handles both model format ({"error": ..., "details": ...}) and
  /// FastAPI validation format ({"detail": [...]}).
  String? _extractBodyError(Map<String, dynamic> decoded) {
    // Model error format: {"error": "...", "details": ...}
    if (decoded['error'] != null) {
      return _errorMessageFromResponse(decoded);
    }
    // FastAPI validation error format: {"detail": [...]}
    if (decoded['detail'] != null) {
      final detail = decoded['detail'];
      if (detail is List && detail.isNotEmpty) {
        return detail
            .map((d) {
              final msg = d['msg']?.toString() ?? '';
              final loc = d['loc'] is List
                  ? (d['loc'] as List).skip(1).join('.')
                  : '';
              return '$msg${loc.isNotEmpty ? ' ($loc)' : ''}';
            })
            .join('; ');
      }
      return detail.toString();
    }
    return null;
  }

  String _filenameFromPath(String path) {
    return path.split(RegExp(r'[\\/]')).last;
  }

  void _logResponseBody(String wordId, String body) {
    const chunkSize = 900;
    if (body.isEmpty) {
      debugPrint('[phoneme-api] response_body word_id=$wordId <empty>');
      return;
    }

    for (var offset = 0; offset < body.length; offset += chunkSize) {
      final end = offset + chunkSize < body.length
          ? offset + chunkSize
          : body.length;
      debugPrint(
        '[phoneme-api] response_body word_id=$wordId '
        'chunk=${offset ~/ chunkSize + 1} ${body.substring(offset, end)}',
      );
    }
  }

  String _errorMessageFromResponse(Map<String, dynamic> decoded) {
    final error =
        decoded['error']?.toString() ?? 'Phoneme model returned an error.';
    final details = decoded['details'];

    if (details is List && details.isNotEmpty) {
      return '$error: ${details.map((item) => item.toString()).join(', ')}';
    }

    if (details != null && details.toString().isNotEmpty) {
      return '$error: $details';
    }

    return error;
  }
}

class PhonemeAssessmentResult {
  final String wordId;
  final String displayWord;
  final String recordingPath;
  final double? overallScore;
  final String? expectedIpa;
  final String? detectedIpa;
  final Map<String, dynamic>? assessment;
  final Map<String, dynamic>? rawResponse;
  final String? rawBody;
  final String? error;
  final double? pcc;
  final double? pccR;
  final double? pvc;
  final String? pccSeverity;
  final bool? passed;

  const PhonemeAssessmentResult({
    required this.wordId,
    required this.displayWord,
    required this.recordingPath,
    required this.overallScore,
    required this.expectedIpa,
    required this.detectedIpa,
    required this.assessment,
    required this.rawResponse,
    required this.rawBody,
    required this.error,
    this.pcc,
    this.pccR,
    this.pvc,
    this.pccSeverity,
    this.passed,
  });

  factory PhonemeAssessmentResult.success({
    required ScreeningWordModel word,
    required String recordingPath,
    required Map<String, dynamic> rawResponse,
  }) {
    return PhonemeAssessmentResult(
      wordId: word.id,
      displayWord: word.displayWord,
      recordingPath: recordingPath,
      overallScore: _asDouble(rawResponse['overall_score']),
      expectedIpa: rawResponse['expected_ipa']?.toString(),
      detectedIpa: rawResponse['detected_ipa']?.toString(),
      assessment: _asMap(rawResponse['assessment']),
      rawResponse: rawResponse,
      rawBody: null,
      error: null,
      pcc: _asDouble(rawResponse['pcc']),
      pccR: _asDouble(rawResponse['pcc_r']),
      pvc: _asDouble(rawResponse['pvc']),
      pccSeverity: rawResponse['pcc_severity']?.toString(),
      passed: _asBool(rawResponse['passed']),
    );
  }

  factory PhonemeAssessmentResult.failure({
    required ScreeningWordModel word,
    required String recordingPath,
    required String error,
    Map<String, dynamic>? rawResponse,
    String? rawBody,
  }) {
    return PhonemeAssessmentResult(
      wordId: word.id,
      displayWord: word.displayWord,
      recordingPath: recordingPath,
      overallScore: null,
      expectedIpa: rawResponse?['expected_ipa']?.toString(),
      detectedIpa: rawResponse?['detected_ipa']?.toString(),
      assessment: _asMap(rawResponse?['assessment']),
      rawResponse: rawResponse,
      rawBody: rawBody,
      error: error,
    );
  }

  bool get isSuccess => error == null && overallScore != null;

  List<Map<String, dynamic>> get detectedProcesses {
    final rawProcesses = assessment?['detected_processes'];
    if (rawProcesses is! List) return const [];

    return rawProcesses
        .whereType<Map>()
        .map((process) => Map<String, dynamic>.from(process))
        .toList();
  }

  String get detectedProcessSummary {
    if (detectedProcesses.isEmpty) return 'No detected process';

    return detectedProcesses
        .map((process) {
          final name = process['process']?.toString() ?? 'Unknown process';
          final position = process['position']?.toString();
          final detail = process['detail']?.toString();

          final parts = <String>[name];
          if (position != null && position.isNotEmpty) parts.add(position);
          if (detail != null && detail.isNotEmpty) parts.add(detail);
          return parts.join(' - ');
        })
        .join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'word_id': wordId,
      'display_word': displayWord,
      'recording_path': recordingPath,
      'overall_score': overallScore,
      'expected_ipa': expectedIpa,
      'detected_ipa': detectedIpa,
      'detected_processes': detectedProcesses,
      'detected_process_summary': detectedProcessSummary,
      'assessment': assessment,
      'pcc': pcc,
      'pcc_r': pccR,
      'pvc': pvc,
      'pcc_severity': pccSeverity,
      'passed': passed,
      'error': error,
      if (rawBody != null) 'raw_body': rawBody,
    };
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static bool? _asBool(Object? value) {
    if (value is bool) return value;
    return null;
  }
}
