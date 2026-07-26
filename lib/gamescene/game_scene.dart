import 'package:flame/game.dart' hide Game;
import 'package:flutter/material.dart';

import 'components/background_component.dart';
import 'components/bubble_bay_component.dart';
import 'components/captains_call_component.dart';
import 'components/coral_cargo_component.dart';
import 'components/feedback_effect_component.dart';
import 'components/level_mechanic_component.dart';
import 'components/mascot_component.dart';
import 'components/mic_visualizer_component.dart';
import 'components/progress_component.dart';
import 'components/reef_route_component.dart';
import 'components/score_animation_component.dart';
import 'components/speech_bubble_component.dart';
import 'components/target_display_component.dart';
import 'game_scene_state.dart';

class GameScene extends FlameGame {
  final ValueNotifier<GameSceneState> sceneStateNotifier;

  late final BackgroundComponent _background;
  late final MascotComponent _mascot;
  late final SpeechBubbleComponent _speechBubble;
  late final ProgressComponent _progress;
  late final MicVisualizerComponent _micVisualizer;
  late final TargetDisplayComponent _targetDisplay;
  late final FeedbackEffectComponent _feedbackEffect;
  late final ScoreAnimationComponent _scoreAnimation;
  late final List<LevelMechanicComponent> _levelMechanics;

  GameSceneState _sceneState;
  bool _componentsLoaded = false;

  GameScene({required GameSceneState initialState})
    : _sceneState = initialState,
      sceneStateNotifier = ValueNotifier<GameSceneState>(initialState);

  GameSceneState get sceneState => _sceneState;

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/';

    _background = BackgroundComponent();
    _mascot = MascotComponent();
    _speechBubble = SpeechBubbleComponent();
    _progress = ProgressComponent();
    _micVisualizer = MicVisualizerComponent();
    _targetDisplay = TargetDisplayComponent();
    _feedbackEffect = FeedbackEffectComponent();
    _scoreAnimation = ScoreAnimationComponent();
    _levelMechanics = [
      BubbleBayComponent(),
      CoralCargoComponent(),
      ReefRouteComponent(),
      CaptainsCallComponent(),
    ];

    await addAll([
      _background,
      ..._levelMechanics,
      _mascot,
      _targetDisplay,
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
    _mascot.sync(_sceneState);
    _speechBubble.sync(_sceneState);
    _progress.sync(_sceneState);
    _micVisualizer.sync(_sceneState);
    _targetDisplay.sync(_sceneState);
    _feedbackEffect.sync(_sceneState);
    _scoreAnimation.sync(_sceneState);
    for (final mechanic in _levelMechanics) {
      mechanic.sync(_sceneState);
    }
  }

  void _layoutComponents(Vector2 gameSize) {
    if (gameSize.x <= 0 || gameSize.y <= 0) return;
    _background.onGameResize(gameSize);
    _mascot.layoutFor(gameSize);
    _speechBubble.layoutFor(gameSize);
    _progress.layoutFor(gameSize);
    _micVisualizer.layoutFor(gameSize);
    _targetDisplay.layoutFor(gameSize);
    _scoreAnimation.layoutFor(gameSize);
    _feedbackEffect.layoutFor(gameSize);
    for (final mechanic in _levelMechanics) {
      mechanic.layoutFor(gameSize);
    }
  }
}
