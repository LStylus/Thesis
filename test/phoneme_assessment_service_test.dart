import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/services/phoneme_assessment_service.dart';
import 'package:thesis/models/screening_word_model.dart';

/// Helper to create a minimal ScreeningWordModel for tests.
ScreeningWordModel _word({
  String id = 'pig_age4',
  String displayWord = 'pig',
}) {
  return ScreeningWordModel(
    id: id,
    audioId: displayWord,
    displayWord: displayWord,
    age: 4,
  );
}

void main() {
  group('PhonemeAssessmentResult.success()', () {
    test('parses all fields from a full model response', () {
      final response = {
        'target_word': 'pig',
        'expected_ipa': 'p,ɪ,ɡ',
        'detected_ipa': 'p,ɪ,k',
        'overall_score': 66.67,
        'age': 4,
        'passed': true,
        'pcc': 66.67,
        'pcc_r': 75.0,
        'pvc': 100.0,
        'pcc_severity': 'Mild-Moderate',
        'phoneme_header': {
          'expected_sequence': 'p,ɪ,ɡ',
          'detected_sequence': 'p,ɪ,k',
        },
        'assessment': {
          'phoneme_breakdown': [
            {
              'expected': 'p',
              'predicted': 'p',
              'score': 100.0,
              'confidence': 0.95,
              'duration_sec': 0.12,
            },
            {
              'expected': 'ɪ',
              'predicted': 'ɪ',
              'score': 100.0,
              'confidence': 0.92,
              'duration_sec': 0.08,
            },
            {
              'expected': 'ɡ',
              'predicted': 'k',
              'score': 0.0,
              'confidence': 0.85,
              'duration_sec': 0.10,
            },
          ],
          'detected_processes': [
            {
              'process': 'stopping',
              'position': 'initial',
              'severity': 'moderate',
            },
          ],
        },
        'quality': {
          'warnings': [],
          'rms_value': 0.05,
        },
      };

      final result = PhonemeAssessmentResult.success(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        rawResponse: response,
      );

      expect(result.wordId, 'pig_age4');
      expect(result.displayWord, 'pig');
      expect(result.recordingPath, '/tmp/recording.wav');
      expect(result.overallScore, 66.67);
      expect(result.expectedIpa, 'p,ɪ,ɡ');
      expect(result.detectedIpa, 'p,ɪ,k');
      expect(result.pcc, 66.67);
      expect(result.pccR, 75.0);
      expect(result.pvc, 100.0);
      expect(result.pccSeverity, 'Mild-Moderate');
      expect(result.passed, true);
      expect(result.error, isNull);
      expect(result.isSuccess, true);
    });

    test('parses passed=false correctly', () {
      final response = {
        'overall_score': 50.0,
        'passed': false,
      };

      final result = PhonemeAssessmentResult.success(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        rawResponse: response,
      );

      expect(result.passed, false);
      expect(result.overallScore, 50.0);
    });

    test('handles null passed field gracefully', () {
      final response = {
        'overall_score': 90.0,
      };

      final result = PhonemeAssessmentResult.success(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        rawResponse: response,
      );

      expect(result.passed, isNull);
      expect(result.overallScore, 90.0);
    });

    test('handles missing optional score fields', () {
      final response = {
        'overall_score': 80.0,
      };

      final result = PhonemeAssessmentResult.success(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        rawResponse: response,
      );

      expect(result.pcc, isNull);
      expect(result.pccR, isNull);
      expect(result.pvc, isNull);
      expect(result.pccSeverity, isNull);
    });

    test('detectedProcesses extracts process list from assessment', () {
      final response = {
        'overall_score': 66.67,
        'assessment': {
          'detected_processes': [
            {'process': 'stopping', 'position': 'initial'},
            {'process': 'fronting', 'position': 'final'},
          ],
        },
      };

      final result = PhonemeAssessmentResult.success(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        rawResponse: response,
      );

      expect(result.detectedProcesses.length, 2);
      expect(result.detectedProcesses[0]['process'], 'stopping');
      expect(result.detectedProcesses[1]['process'], 'fronting');
    });

    test('detectedProcesses returns empty list for no processes', () {
      final response = {
        'overall_score': 100.0,
        'assessment': {
          'detected_processes': [],
        },
      };

      final result = PhonemeAssessmentResult.success(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        rawResponse: response,
      );

      expect(result.detectedProcesses, isEmpty);
    });

    test('detectedProcesses returns empty list if assessment is null', () {
      final response = {
        'overall_score': 100.0,
      };

      final result = PhonemeAssessmentResult.success(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        rawResponse: response,
      );

      expect(result.detectedProcesses, isEmpty);
    });

    test('detectedProcessSummary formats processes correctly', () {
      final response = {
        'overall_score': 66.67,
        'assessment': {
          'detected_processes': [
            {'process': 'stopping', 'position': 'initial', 'detail': '/p/ → /b/'},
          ],
        },
      };

      final result = PhonemeAssessmentResult.success(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        rawResponse: response,
      );

      expect(result.detectedProcessSummary, contains('stopping'));
      expect(result.detectedProcessSummary, contains('initial'));
      expect(result.detectedProcessSummary, contains('/p/ → /b/'));
    });

    test('detectedProcessSummary returns "No detected process" when empty', () {
      final response = {
        'overall_score': 100.0,
      };

      final result = PhonemeAssessmentResult.success(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        rawResponse: response,
      );

      expect(result.detectedProcessSummary, 'No detected process');
    });
  });

  group('PhonemeAssessmentResult.failure()', () {
    test('captures error and nulls out scores', () {
      final result = PhonemeAssessmentResult.failure(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        error: 'Invalid Audio: Audio is too quiet',
      );

      expect(result.error, 'Invalid Audio: Audio is too quiet');
      expect(result.overallScore, isNull);
      expect(result.isSuccess, false);
      expect(result.detectedProcesses, isEmpty);
    });

    test('includes rawResponse when provided', () {
      final rawResponse = {'error': 'Invalid Audio', 'details': ['too quiet']};

      final result = PhonemeAssessmentResult.failure(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        error: 'Invalid Audio: too quiet',
        rawResponse: rawResponse,
      );

      expect(result.rawResponse, rawResponse);
    });
  });

  group('PhonemeAssessmentResult.isSuccess', () {
    test('true when error is null and overallScore is set', () {
      final response = {'overall_score': 90.0};
      final result = PhonemeAssessmentResult.success(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        rawResponse: response,
      );
      expect(result.isSuccess, true);
    });

    test('false when error is set', () {
      final result = PhonemeAssessmentResult.failure(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        error: 'Something went wrong',
      );
      expect(result.isSuccess, false);
    });
  });

  group('PhonemeAssessmentResult.toJson()', () {
    test('includes all fields in round-trip', () {
      final response = {
        'overall_score': 85.0,
        'pcc': 85.0,
        'pcc_r': 90.0,
        'pvc': 100.0,
        'pcc_severity': 'Mild',
        'passed': true,
      };

      final result = PhonemeAssessmentResult.success(
        word: _word(),
        recordingPath: '/tmp/recording.wav',
        rawResponse: response,
      );

      final json = result.toJson();
      expect(json['overall_score'], 85.0);
      expect(json['pcc'], 85.0);
      expect(json['pcc_r'], 90.0);
      expect(json['pvc'], 100.0);
      expect(json['pcc_severity'], 'Mild');
      expect(json['passed'], true);
      expect(json['word_id'], 'pig_age4');
      expect(json['display_word'], 'pig');
      expect(json['error'], null);
    });
  });
}
