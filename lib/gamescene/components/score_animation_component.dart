import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_fonts.dart';
import '../game_scene_state.dart';
import 'illustrated_asset_component.dart';

class ScoreAnimationComponent extends PositionComponent {
  late final IllustratedAssetComponent _successBadge;
  late final IllustratedAssetComponent _retryBadge;
  late final TextComponent _scoreText;
  GameSceneState _state = GameSceneState.initial();
  double _displayedScore = 0;
  double _time = 0;
  bool _loaded = false;

  ScoreAnimationComponent() : super(anchor: Anchor.center, priority: 35);

  @override
  Future<void> onLoad() async {
    _successBadge = IllustratedAssetComponent(
      assetPath: 'game/shared/success_badge_small.svg',
      anchor: Anchor.center,
    );
    _retryBadge = IllustratedAssetComponent(
      assetPath: 'game/shared/retry_prompt_visual.svg',
      anchor: Anchor.center,
    );
    _scoreText = TextComponent(
      anchor: Anchor.center,
      priority: 2,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF31566B),
          fontFamily: AppFonts.fredoka,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
    await addAll([_successBadge, _retryBadge, _scoreText]);
    _loaded = true;
    _syncVisibility();
  }

  void sync(GameSceneState state) {
    if (state.score != _state.score) {
      _displayedScore = 0;
      _time = 0;
    }
    _state = state;
    _syncVisibility();
  }

  void _syncVisibility() {
    if (!_loaded) return;
    _successBadge.visible = _state.phase == GamePhase.correct;
    _retryBadge.visible = _state.phase == GamePhase.retry;
    _scoreText.text =
        _state.score == null ||
            (_state.phase != GamePhase.correct &&
                _state.phase != GamePhase.retry)
        ? ''
        : '${_displayedScore.round()}%';
  }

  void layoutFor(Vector2 gameSize) {
    final badgeSize = (gameSize.y * 0.18).clamp(82.0, 108.0).toDouble();
    size = Vector2.all(badgeSize);
    position = Vector2(gameSize.x * 0.30, gameSize.y * 0.66);
    for (final badge in [_successBadge, _retryBadge]) {
      badge
        ..size = Vector2.all(badgeSize)
        ..position = Vector2.all(badgeSize / 2);
    }
    _scoreText.position = Vector2(badgeSize / 2, badgeSize * 0.50);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final target = (_state.score ?? 0).toDouble();
    _displayedScore += (target - _displayedScore) * (1 - math.pow(0.001, dt));
    final pulse = 1 + math.sin(_time * math.pi * 3) * 0.035;
    if (_loaded) {
      _successBadge.scale = Vector2.all(pulse);
      _retryBadge.scale = Vector2.all(pulse);
      _scoreText.text = _state.score == null
          ? ''
          : '${_displayedScore.round()}%';
    }
  }
}
