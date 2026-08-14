import '../../../models/screening_word_model.dart';
import '../../../services/audio_recording_service.dart';
import '../../../services/phoneme_assessment_service.dart';

abstract class GameRecorder {
  Stream<double> get amplitudeLevels;
  Future<GameRecorderReadiness> prepare();
  Future<String?> recordTimed({
    required String fileNamePrefix,
    required Duration duration,
  });

  Future<void> cancel();
  Future<void> dispose();
}

enum GameRecorderReadiness { ready, permissionDenied, unavailable }

class AudioGameRecorder implements GameRecorder {
  final AudioRecordingService _service;

  AudioGameRecorder({AudioRecordingService? service})
    : _service = service ?? AudioRecordingService();

  @override
  Stream<double> get amplitudeLevels => _service.amplitudeLevels;

  @override
  Future<GameRecorderReadiness> prepare() async {
    final ready = await _service.initialize();
    if (ready) return GameRecorderReadiness.ready;
    return _service.hasMicPermission
        ? GameRecorderReadiness.unavailable
        : GameRecorderReadiness.permissionDenied;
  }

  @override
  Future<String?> recordTimed({
    required String fileNamePrefix,
    required Duration duration,
  }) {
    return _service.recordTimed(
      fileNamePrefix: fileNamePrefix,
      duration: duration,
    );
  }

  @override
  Future<void> cancel() => _service.cancel();

  @override
  Future<void> dispose() => _service.dispose();
}

abstract class GameAssessmentClient {
  Future<PhonemeAssessmentResult> assess({
    required ScreeningWordModel word,
    required String recordingPath,
  });
}

class Model2GameAssessmentClient implements GameAssessmentClient {
  final PhonemeAssessmentService _service;

  Model2GameAssessmentClient({PhonemeAssessmentService? service})
    : _service = service ?? PhonemeAssessmentService();

  @override
  Future<PhonemeAssessmentResult> assess({
    required ScreeningWordModel word,
    required String recordingPath,
  }) {
    return _service.assess(word: word, recordingPath: recordingPath);
  }
}
