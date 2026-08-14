import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

import '../../features/game/domain/game_template_kind.dart';
import '../game_scene.dart';
import '../game_scene_state.dart';

class ExplorerComponent extends PositionComponent
    with HasGameReference<GameScene> {
  late final Svg _idle;
  late final Svg _happy;
  GameSceneState _state = GameSceneState.initial();
  double _time = 0;
  Vector2 _gameSize = Vector2.zero();

  ExplorerComponent() : super(anchor: Anchor.center, priority: 24);

  @override
  Future<void> onLoad() async {
    _idle = await game.loadSvg('game/adventure/child_explorer_idle.svg');
    _happy = await game.loadSvg('game/adventure/child_explorer_happy.svg');
  }

  void sync(GameSceneState state) {
    _state = state;
  }

  void layoutFor(Vector2 gameSize) {
    _gameSize = gameSize;
    final height = (gameSize.y * 0.34).clamp(100.0, 190.0).toDouble();
    size = Vector2(height * 220 / 300, height);
    position = Vector2(gameSize.x * 0.18, gameSize.y * 0.70);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    if (_gameSize.x > 0) {
      final crossedBridge =
          _state.template == GameTemplateKind.voicePoweredJourney &&
          (_state.phase == GamePhase.correct ||
              _state.phase == GamePhase.completed);
      final targetX = _gameSize.x * (crossedBridge ? .59 : .18);
      position.x += (targetX - position.x) * (1 - math.pow(.004, dt));
    }
  }

  @override
  void render(Canvas canvas) {
    final celebrating =
        _state.phase == GamePhase.correct ||
        _state.phase == GamePhase.completed;
    final bounce = celebrating
        ? math.sin(_time * math.pi * 5).abs() * size.y * 0.06
        : math.sin(_time * math.pi * 1.6) * size.y * 0.012;
    canvas.save();
    canvas.translate(0, -bounce);
    (celebrating ? _happy : _idle).render(canvas, size);
    canvas.restore();
  }
}
