import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thesis/game/core/feedback_effect_component.dart';
import 'package:thesis/game/core/mic_visualizer_component.dart';
import 'package:thesis/game/core/progress_component.dart';
import 'package:thesis/game/core/speech_bubble_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'visual utilities render without the removed scene, services, or state',
    () {
      final canvasRecorder = ui.PictureRecorder();
      final canvas = ui.Canvas(canvasRecorder);
      final size = Vector2(800, 360);
      final mic = MicVisualizerComponent()..layoutFor(size);
      final progress = ProgressComponent()..layoutFor(size);
      final prompt = SpeechBubbleComponent()..layoutFor(size);
      final feedback = FeedbackEffectComponent()..layoutFor(size);

      mic.render(canvas);
      mic.recording = true;
      mic.micLevel = 0.6;
      mic.micProgress = 0.5;
      mic.countdown = 2;
      mic.update(0.1);
      mic.render(canvas);
      mic.recording = false;
      mic.checking = true;
      mic.render(canvas);
      mic.visible = false;
      mic.render(canvas);
      progress.setProgress('1 / 3');
      progress.render(canvas);
      prompt.setMessage('Your turn');
      prompt.render(canvas);
      prompt.setMessage('Try again when ready', isError: true);
      prompt.render(canvas);
      feedback.showFeedback(success: true);
      feedback.update(0.1);
      feedback.render(canvas);
      feedback.showFeedback(success: false);
      feedback.update(2);
      feedback.render(canvas);
      canvasRecorder.endRecording().dispose();
      expect(mic.isMounted, isFalse);
    },
  );
}
