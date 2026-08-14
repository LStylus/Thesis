import 'package:audioplayers/audioplayers.dart';

import '../../../models/screening_word_model.dart';
import '../../../services/audio_recording_service.dart';
import '../../../services/phoneme_assessment_service.dart';

/// Plays the target prompt audio before recording (may be silent when the
/// target has no audio asset).  Abstract so tests can inject a no-op.
abstract class PromptAudioPlayer {
  Future<void> playAsset(String assetPath);
  void dispose();
}

class AudioPlayersPromptAudio implements PromptAudioPlayer {
  final AudioPlayer _player;

  AudioPlayersPromptAudio({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  @override
  Future<void> playAsset(String assetPath) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // audio is a nicety — never break the game flow
    }
  }

  @override
  void dispose() {
    try {
      _player.dispose();
    } catch (_) {}
  }
}

class NoopPromptAudio implements PromptAudioPlayer {
  @override
  Future<void> playAsset(String assetPath) async {}

  @override
  void dispose() {}
}

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
