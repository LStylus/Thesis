import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/features/game/application/game_services.dart';
import 'package:thesis/features/game/application/game_session_controller.dart';
import 'package:thesis/features/game/domain/game_level_config.dart';
import 'package:thesis/gamescene/game_scene_state.dart';
import 'package:thesis/models/screening_word_model.dart';
import 'package:thesis/services/phoneme_assessment_service.dart';

void main() {
  test('recording starts only after the Flame interaction completes', () async {
    final recorder = _FakeRecorder();
    final controller = _controller(
      recorder: recorder,
      timings: const GameSessionTimings(
        recordingDuration: Duration(milliseconds: 1),
        levelCaptionDuration: Duration.zero,
        targetCaptionDuration: Duration(milliseconds: 40),
        feedbackHold: Duration.zero,
        successHold: Duration.zero,
      ),
    );

    controller.start();
    controller.start();
    await _waitUntil(() => controller.state.phase == GamePhase.interaction);

    expect(recorder.recordCalls, 0);
    expect(recorder.prepareCalls, 1);
    controller.completeInteraction();
    expect(controller.state.message, startsWith('Get ready:'));

    await _waitUntil(() => recorder.recordCalls > 0);
    await controller.cancel();
    controller.dispose();
  });

  test('correct assessments complete every personalized target', () async {
    final controller = _controller();
    controller.start();
    await _driveToCompletion(controller);

    final targetCount = controller.state.targets.length;
    expect(controller.state.completedTargetIds, hasLength(targetCount));
    expect(controller.state.targetAccuracies, hasLength(targetCount));
    expect(controller.state.averageAccuracy(), 95);
    expect(controller.completionResult.value, isNull);

    controller.finishLevel();
    expect(controller.completionResult.value?.levelIndex, 0);
    expect(
      controller.completionResult.value?.attemptedTargetCount,
      targetCount,
    );
    controller.dispose();
  });

  test('retry result repeats only the current target', () async {
    final recorder = _FakeRecorder();
    final assessment = _FakeAssessmentClient(scores: [45, 92]);
    final controller = _controller(recorder: recorder, assessment: assessment);
    final targetCount = controller.state.targets.length;
    controller.start();
    await _driveToCompletion(controller);

    expect(recorder.recordCalls, targetCount + 1);
    expect(controller.state.completedTargetIds, hasLength(targetCount));
    expect(controller.state.needsPracticeTargetIds, isEmpty);
    controller.dispose();
  });

  test('invalid recording is not scored and can be retried', () async {
    final recorder = _FakeRecorder(recordingResults: [null]);
    final controller = _controller(recorder: recorder);
    final targetCount = controller.state.targets.length;
    controller.start();
    await _waitUntil(() => controller.state.phase == GamePhase.interaction);
    controller.completeInteraction();

    await _waitUntil(() => controller.state.phase == GamePhase.invalidAudio);
    expect(controller.state.targetAccuracies, isEmpty);
    expect(controller.state.targetIndex, 0);

    controller.retryCurrent();
    await _driveToCompletion(controller);

    expect(recorder.recordCalls, targetCount + 1);
    expect(controller.state.targetAccuracies, hasLength(targetCount));
    controller.dispose();
  });

  test(
    'bounded retries save a target for review and keep play moving',
    () async {
      final assessment = _FakeAssessmentClient(scores: [20, 30, 40]);
      final controller = _controller(assessment: assessment);
      final targetCount = controller.state.targets.length;
      controller.start();
      await _driveToCompletion(controller);

      expect(controller.state.completedTargetIds, hasLength(targetCount));
      expect(controller.state.needsPracticeTargetIds, hasLength(1));
      controller.finishLevel();
      expect(controller.completionResult.value?.needsPracticeCount, 1);
      controller.dispose();
    },
  );

  test('microphone permission denial stops before interaction', () async {
    final recorder = _FakeRecorder(
      readiness: GameRecorderReadiness.permissionDenied,
    );
    final controller = _controller(recorder: recorder);
    controller.start();

    await _waitUntil(() => controller.state.phase == GamePhase.error);

    expect(recorder.recordCalls, 0);
    expect(controller.state.message, contains('Microphone permission'));
    controller.dispose();
  });

  test('assessment failure is never converted into success', () async {
    final assessment = _FakeAssessmentClient(failFirst: true);
    final controller = _controller(assessment: assessment);
    controller.start();
    await _waitUntil(() => controller.state.phase == GamePhase.interaction);
    controller.completeInteraction();

    await _waitUntil(() => controller.state.phase == GamePhase.error);

    expect(controller.state.completedTargetIds, isEmpty);
    expect(controller.state.targetAccuracies, isEmpty);
    controller.dispose();
  });

  test('pause cancels work and resume restores the interaction gate', () async {
    final recorder = _FakeRecorder();
    final controller = _controller(recorder: recorder);
    controller.start();
    await _waitUntil(() => controller.state.phase == GamePhase.interaction);

    await controller.pause();
    expect(recorder.cancelCalls, greaterThanOrEqualTo(1));
    expect(recorder.recordCalls, 0);

    controller.resume();
    await _driveToCompletion(controller);
    expect(
      controller.state.completedTargetIds,
      hasLength(controller.state.targets.length),
    );
    controller.dispose();
  });
}

GameSessionController _controller({
  _FakeRecorder? recorder,
  _FakeAssessmentClient? assessment,
  GameSessionTimings? timings,
}) {
  return GameSessionController(
    config: GameLevelConfig(
      childProfileId: 'child-1',
      childName: 'Kai',
      childAge: 6,
      levelIndex: 0,
    ),
    recorder: recorder ?? _FakeRecorder(),
    assessmentClient: assessment ?? _FakeAssessmentClient(),
    timings:
        timings ??
        const GameSessionTimings(
          recordingDuration: Duration(milliseconds: 1),
          levelCaptionDuration: Duration.zero,
          targetCaptionDuration: Duration.zero,
          feedbackHold: Duration.zero,
          successHold: Duration.zero,
        ),
  );
}

Future<void> _driveToCompletion(GameSessionController controller) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (controller.state.phase != GamePhase.completed) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out while driving the game session.');
    }
    if (controller.state.phase == GamePhase.interaction) {
      controller.completeInteraction();
    }
    if (controller.state.phase == GamePhase.error ||
        controller.state.phase == GamePhase.invalidAudio) {
      fail('Session stopped in ${controller.state.phase}.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

Future<void> _waitUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Timed out while waiting for the game session state.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

class _FakeRecorder implements GameRecorder {
  final List<String> events;
  final List<String?> recordingResults;
  final GameRecorderReadiness readiness;
  int prepareCalls = 0;
  int recordCalls = 0;
  int cancelCalls = 0;

  _FakeRecorder({
    List<String>? events,
    List<String?>? recordingResults,
    this.readiness = GameRecorderReadiness.ready,
  }) : events = events ?? [],
       recordingResults = recordingResults ?? [];

  @override
  Stream<double> get amplitudeLevels => const Stream.empty();

  @override
  Future<GameRecorderReadiness> prepare() async {
    prepareCalls++;
    return readiness;
  }

  @override
  Future<String?> recordTimed({
    required String fileNamePrefix,
    required Duration duration,
  }) async {
    final call = ++recordCalls;
    events.add('record:start:$call');
    if (call <= recordingResults.length) return recordingResults[call - 1];
    return 'recording-$call.wav';
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }

  @override
  Future<void> dispose() async {}
}

class _FakeAssessmentClient implements GameAssessmentClient {
  final List<int> scores;
  final bool failFirst;
  int callCount = 0;

  _FakeAssessmentClient({List<int>? scores, this.failFirst = false})
    : scores = scores ?? [];

  @override
  Future<PhonemeAssessmentResult> assess({
    required ScreeningWordModel word,
    required String recordingPath,
  }) async {
    final call = callCount++;
    if (failFirst && call == 0) {
      return PhonemeAssessmentResult.failure(
        word: word,
        recordingPath: recordingPath,
        error: 'Service unavailable',
      );
    }
    final score = call < scores.length ? scores[call] : 95;
    return PhonemeAssessmentResult.success(
      word: word,
      recordingPath: recordingPath,
      rawResponse: {
        'overall_score': score,
        'expected_ipa': '',
        'detected_ipa': '',
        'assessment': <String, dynamic>{},
      },
    );
  }
}
