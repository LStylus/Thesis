import '../models/screening_word_model.dart';
import 'phoneme_assessment_service.dart';

/// Bridge type — delegates to [PhonemeAssessmentService].
class Model2AssessmentService {
  final PhonemeAssessmentService _inner;

  Model2AssessmentService({String? baseUrl})
    : _inner = PhonemeAssessmentService(baseUrl: baseUrl);

  String get baseUrl => _inner.baseUrl;

  Future<Model2AssessmentResult> assess({
    required ScreeningWordModel word,
    required String recordingPath,
  }) async {
    final result = await _inner.assess(
      word: word,
      recordingPath: recordingPath,
      age: word.age,
    );
    return Model2AssessmentResult._fromPhoneme(result);
  }
}

/// Bridge type — wraps [PhonemeAssessmentResult] with an identical public API.
class Model2AssessmentResult {
  final PhonemeAssessmentResult _inner;

  Model2AssessmentResult._fromPhoneme(this._inner);

  /// Wrap an existing [PhonemeAssessmentResult] as a [Model2AssessmentResult].
  factory Model2AssessmentResult.fromPhoneme(PhonemeAssessmentResult result) =>
      Model2AssessmentResult._fromPhoneme(result);

  factory Model2AssessmentResult.success({
    required ScreeningWordModel word,
    required String recordingPath,
    required Map<String, dynamic> rawResponse,
  }) {
    return Model2AssessmentResult._fromPhoneme(
      PhonemeAssessmentResult.success(
        word: word,
        recordingPath: recordingPath,
        rawResponse: rawResponse,
      ),
    );
  }

  factory Model2AssessmentResult.failure({
    required ScreeningWordModel word,
    required String recordingPath,
    required String error,
    Map<String, dynamic>? rawResponse,
    String? rawBody,
  }) {
    return Model2AssessmentResult._fromPhoneme(
      PhonemeAssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: error,
        rawResponse: rawResponse,
        rawBody: rawBody,
      ),
    );
  }

  // ── Delegated fields ──────────────────────────────────────────────────────

  String get wordId => _inner.wordId;
  String get displayWord => _inner.displayWord;
  String get recordingPath => _inner.recordingPath;
  double? get overallScore => _inner.overallScore;
  String? get expectedIpa => _inner.expectedIpa;
  String? get detectedIpa => _inner.detectedIpa;
  Map<String, dynamic>? get assessment => _inner.assessment;
  Map<String, dynamic>? get rawResponse => _inner.rawResponse;
  String? get rawBody => _inner.rawBody;
  String? get error => _inner.error;
  double? get pcc => _inner.pcc;
  double? get pccR => _inner.pccR;
  double? get pvc => _inner.pvc;
  String? get pccSeverity => _inner.pccSeverity;
  bool? get passed => _inner.passed;
  bool get isSuccess => _inner.isSuccess;
  List<Map<String, dynamic>> get detectedProcesses => _inner.detectedProcesses;
  String get detectedProcessSummary => _inner.detectedProcessSummary;

  Map<String, dynamic> toJson() => _inner.toJson();
}
