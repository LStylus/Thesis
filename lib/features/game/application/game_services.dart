import '../../../models/screening_word_model.dart';
import '../../../services/audio_recording_service.dart';
import '../../../services/model_2_assessment_service.dart';

abstract class GameRecorder {
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
  Future<Model2AssessmentResult> assess({
    required ScreeningWordModel word,
    required String recordingPath,
  });
}

class Model2GameAssessmentClient implements GameAssessmentClient {
  final Model2AssessmentService _service;

  Model2GameAssessmentClient({Model2AssessmentService? service})
    : _service = service ?? Model2AssessmentService();

  @override
  Future<Model2AssessmentResult> assess({
    required ScreeningWordModel word,
    required String recordingPath,
  }) {
    return _service.assess(word: word, recordingPath: recordingPath);
  }
}
