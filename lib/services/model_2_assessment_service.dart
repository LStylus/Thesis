import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
      return 'http://192.168.1.11:8001';
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
    final file = File(recordingPath);
    if (!await file.exists()) {
      return Model2AssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: 'Recording file was not found.',
      );
    }

    try {
      final request = http.MultipartRequest('POST', _assessUri)
        ..fields['word'] = word.displayWord.toLowerCase()
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            recordingPath,
            filename: _filenameFromPath(recordingPath),
          ),
        );

      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2),
      );
      final response = await http.Response.fromStream(streamedResponse);

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
        return Model2AssessmentResult.failure(
          word: word,
          recordingPath: recordingPath,
          error: decoded['error'].toString(),
          rawResponse: decoded,
        );
      }

      return Model2AssessmentResult.success(
        word: word,
        recordingPath: recordingPath,
        rawResponse: decoded,
      );
    } on TimeoutException {
      return Model2AssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: 'Model-2 request timed out.',
      );
    } on SocketException {
      return Model2AssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: 'Could not connect to Model-2 at $baseUrl.',
      );
    } on FormatException {
      return Model2AssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: 'Model-2 returned an invalid response.',
      );
    } catch (error) {
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

  Map<String, dynamic> toJson() {
    return {
      'word_id': wordId,
      'display_word': displayWord,
      'recording_path': recordingPath,
      'overall_score': overallScore,
      'expected_ipa': expectedIpa,
      'detected_ipa': detectedIpa,
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
