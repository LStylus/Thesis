import 'package:flame/game.dart' hide Game;
import 'package:flutter/material.dart';

import 'components/background_component.dart';
import 'components/explorer_component.dart';
import 'components/feedback_effect_component.dart';
import 'components/mic_visualizer_component.dart';
import 'components/progress_component.dart';
import 'components/score_animation_component.dart';
import 'components/speech_bubble_component.dart';
import 'components/template_mechanic_component.dart';
import 'game_scene_state.dart';

class GameScene extends FlameGame {
  final ValueNotifier<GameSceneState> sceneStateNotifier;
  final VoidCallback onInteractionCompleted;

  late final BackgroundComponent _background;
  late final ExplorerComponent _explorer;
  late final TemplateMechanicComponent _mechanic;
  late final SpeechBubbleComponent _speechBubble;
  late final ProgressComponent _progress;
  late final MicVisualizerComponent _micVisualizer;
  late final FeedbackEffectComponent _feedbackEffect;
  late final ScoreAnimationComponent _scoreAnimation;

  GameSceneState _sceneState;
  bool _componentsLoaded = false;

  GameScene({
    required GameSceneState initialState,
    required this.onInteractionCompleted,
  }) : _sceneState = initialState,
       sceneStateNotifier = ValueNotifier<GameSceneState>(initialState);

  GameSceneState get sceneState => _sceneState;

  @override
  Color backgroundColor() => const Color(0xFF87D9EE);

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';

    _background = BackgroundComponent();
    _explorer = ExplorerComponent();
    _mechanic = TemplateMechanicComponent(
      onInteractionCompleted: onInteractionCompleted,
    );
    _speechBubble = SpeechBubbleComponent();
    _progress = ProgressComponent();
    _micVisualizer = MicVisualizerComponent();
    _feedbackEffect = FeedbackEffectComponent();
    _scoreAnimation = ScoreAnimationComponent();

    await addAll([
      _background,
      _explorer,
      _mechanic,
      _speechBubble,
      _progress,
      _micVisualizer,
      _scoreAnimation,
      _feedbackEffect,
    ]);

    _componentsLoaded = true;
    _syncComponents();
    _layoutComponents(size);
  }

  void updateScene(GameSceneState state) {
    _sceneState = state;
    sceneStateNotifier.value = state;
    if (_componentsLoaded) {
      _syncComponents();
      _layoutComponents(size);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_componentsLoaded) _layoutComponents(size);
  }

  @override
  void onRemove() {
    sceneStateNotifier.dispose();
    super.onRemove();
  }

  void _syncComponents() {
    _background.sync(_sceneState);
    _explorer.sync(_sceneState);
    _mechanic.sync(_sceneState);
    _speechBubble.sync(_sceneState);
    _progress.sync(_sceneState);
    _micVisualizer.sync(_sceneState);
    _feedbackEffect.sync(_sceneState);
    _scoreAnimation.sync(_sceneState);
  }

  void _layoutComponents(Vector2 gameSize) {
    if (gameSize.x <= 0 || gameSize.y <= 0) return;
    _background.onGameResize(gameSize);
    _explorer.layoutFor(gameSize);
    _mechanic.layoutFor(gameSize);
    _speechBubble.layoutFor(gameSize);
    _progress.layoutFor(gameSize);
    _micVisualizer.layoutFor(gameSize);
    _scoreAnimation.layoutFor(gameSize);
    _feedbackEffect.layoutFor(gameSize);
  }
}
