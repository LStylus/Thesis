import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/screening_word_model.dart';

class Model2AssessmentService {
  Model2AssessmentService({String? baseUrl})
    : baseUrl = baseUrl ?? defaultBaseUrl;

  final String baseUrl;

  static const String _definedBaseUrl = String.fromEnvironment(
    'MODEL_2_BASE_URL',
  );

  static String get defaultBaseUrl {
    if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'https://wystan28-PhonemeRecognizer.hf.space';
    }
    return 'http://127.0.0.1:8001';
  }

  Uri get _assessUri {
    return Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/assess');
  }

  Future<Model2AssessmentResult> assess({
    required ScreeningWordModel word,
    required String recordingPath,
  }) async {
    final requestStartedAt = DateTime.now();
    debugPrint(
      '[model-api] assess_start word=${word.displayWord} '
      'word_id=${word.id} base_url=$baseUrl uri=$_assessUri '
      'recording_path=$recordingPath',
    );

    final file = File(recordingPath);
    if (!await file.exists()) {
      debugPrint(
        '[model-api] assess_abort word_id=${word.id} reason=file_not_found',
      );
      return Model2AssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: 'Recording file was not found.',
      );
    }

    try {
      final fileSize = await file.length();
      debugPrint(
        '[model-api] upload_prepare word_id=${word.id} '
        'filename=${_filenameFromPath(recordingPath)} bytes=$fileSize',
      );

      final request = http.MultipartRequest('POST', _assessUri)
        ..fields['word'] = word.displayWord.toLowerCase()
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            recordingPath,
            filename: _filenameFromPath(recordingPath),
            contentType: MediaType('audio', 'wav'),
          ),
        );

      debugPrint(
        '[model-api] upload_send word_id=${word.id} '
        'field_word=${request.fields['word']} file_field=file',
      );

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      final response = await http.Response.fromStream(streamedResponse);
      final elapsedMs = DateTime.now()
          .difference(requestStartedAt)
          .inMilliseconds;

      debugPrint(
        '[model-api] response_received word_id=${word.id} '
        'status=${response.statusCode} elapsed_ms=$elapsedMs',
      );
      _logResponseBody(word.id, response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return Model2AssessmentResult.failure(
          word: word,
          recordingPath: recordingPath,
          error: 'Model-2 returned HTTP ${response.statusCode}.',
          rawBody: response.body,
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['error'] != null) {
        debugPrint(
          '[model-api] response_error word_id=${word.id} '
          'message=${_errorMessageFromResponse(decoded)}',
        );
        return Model2AssessmentResult.failure(
          word: word,
          recordingPath: recordingPath,
          error: _errorMessageFromResponse(decoded),
          rawResponse: decoded,
        );
      }

      final success = Model2AssessmentResult.success(
        word: word,
        recordingPath: recordingPath,
        rawResponse: decoded,
      );
      debugPrint(
        '[model-api] response_success word_id=${word.id} '
        'score=${success.overallScore} expected=${success.expectedIpa} '
        'detected=${success.detectedIpa} '
        'process_count=${success.detectedProcesses.length} '
        'processes=${success.detectedProcessSummary}',
      );
      return success;
    } on TimeoutException {
      debugPrint('[model-api] timeout word_id=${word.id} uri=$_assessUri');
      return Model2AssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: 'Model-2 request timed out.',
      );
    } on SocketException {
      debugPrint('[model-api] socket_error word_id=${word.id} uri=$_assessUri');
      return Model2AssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: 'Could not connect to Model-2 at $baseUrl.',
      );
    } on FormatException {
      debugPrint('[model-api] format_error word_id=${word.id}');
      return Model2AssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: 'Model-2 returned an invalid response.',
      );
    } catch (error) {
      debugPrint(
        '[model-api] unexpected_error word_id=${word.id} error=$error',
      );
      return Model2AssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: 'Model-2 assessment failed: $error',
      );
    }
  }

  String _filenameFromPath(String path) {
    return path.split(RegExp(r'[\\/]')).last;
  }

  void _logResponseBody(String wordId, String body) {
    const chunkSize = 900;
    if (body.isEmpty) {
      debugPrint('[model-api] response_body word_id=$wordId <empty>');
      return;
    }

    for (var offset = 0; offset < body.length; offset += chunkSize) {
      final end = offset + chunkSize < body.length
          ? offset + chunkSize
          : body.length;
      debugPrint(
        '[model-api] response_body word_id=$wordId '
        'chunk=${offset ~/ chunkSize + 1} ${body.substring(offset, end)}',
      );
    }
  }

  String _errorMessageFromResponse(Map<String, dynamic> decoded) {
    final error = decoded['error']?.toString() ?? 'Model-2 returned an error.';
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

class Model2AssessmentResult {
  final String wordId;
  final String displayWord;
  final String recordingPath;
  final double? overallScore;
  final String? expectedIpa;
  final String? detectedIpa;
  final Map<String, dynamic>? assessment;
  final Map<String, dynamic>? stats;
  final Map<String, dynamic>? rawResponse;
  final String? rawBody;
  final String? error;

  const Model2AssessmentResult({
    required this.wordId,
    required this.displayWord,
    required this.recordingPath,
    required this.overallScore,
    required this.expectedIpa,
    required this.detectedIpa,
    required this.assessment,
    required this.stats,
    required this.rawResponse,
    required this.rawBody,
    required this.error,
  });

  factory Model2AssessmentResult.success({
    required ScreeningWordModel word,
    required String recordingPath,
    required Map<String, dynamic> rawResponse,
  }) {
    return Model2AssessmentResult(
      wordId: word.id,
      displayWord: word.displayWord,
      recordingPath: recordingPath,
      overallScore: _asDouble(rawResponse['overall_score']),
      expectedIpa: rawResponse['expected_ipa']?.toString(),
      detectedIpa: rawResponse['detected_ipa']?.toString(),
      assessment: _asMap(rawResponse['assessment']),
      stats: _asMap(rawResponse['stats']),
      rawResponse: rawResponse,
      rawBody: null,
      error: null,
    );
  }

  factory Model2AssessmentResult.failure({
    required ScreeningWordModel word,
    required String recordingPath,
    required String error,
    Map<String, dynamic>? rawResponse,
    String? rawBody,
  }) {
    return Model2AssessmentResult(
      wordId: word.id,
      displayWord: word.displayWord,
      recordingPath: recordingPath,
      overallScore: null,
      expectedIpa: rawResponse?['expected_ipa']?.toString(),
      detectedIpa: rawResponse?['detected_ipa']?.toString(),
      assessment: _asMap(rawResponse?['assessment']),
      stats: _asMap(rawResponse?['stats']),
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
      'stats': stats,
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
}
