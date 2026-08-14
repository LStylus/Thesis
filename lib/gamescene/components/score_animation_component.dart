import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_svg/flame_svg.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_fonts.dart';
import '../game_scene.dart';
import '../game_scene_state.dart';

class ScoreAnimationComponent extends PositionComponent
    with HasGameReference<GameScene> {
  late final Svg _rewardStar;
  GameSceneState _state = GameSceneState.initial();
  double _displayedScore = 0;
  double _time = 0;

  ScoreAnimationComponent() : super(anchor: Anchor.center, priority: 35);

  @override
  Future<void> onLoad() async {
    _rewardStar = await game.loadSvg('game/adventure/reward_star.svg');
  }

  void sync(GameSceneState state) {
    if (state.score != _state.score) {
      _displayedScore = 0;
      _time = 0;
    }
    _state = state;
  }

  void layoutFor(Vector2 gameSize) {
    final badgeSize = (gameSize.y * 0.19).clamp(76.0, 108.0).toDouble();
    size = Vector2.all(badgeSize);
    position = Vector2(gameSize.x * 0.29, gameSize.y * 0.66);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final target = (_state.score ?? 0).toDouble();
    _displayedScore += (target - _displayedScore) * (1 - math.pow(.001, dt));
  }

  @override
  void render(Canvas canvas) {
    final success = _state.phase == GamePhase.correct;
    final retry = _state.phase == GamePhase.retry;
    if (!success && !retry) return;

    final pulse = success ? 1 + math.sin(_time * math.pi * 3) * .04 : 1.0;
    final center = Offset(size.x / 2, size.y / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pulse);
    canvas.translate(-center.dx, -center.dy);
    if (success) {
      _rewardStar.render(canvas, size);
    } else {
      canvas.drawCircle(
        center.translate(0, 4),
        size.x * .45,
        Paint()..color = const Color(0xFF815037).withValues(alpha: .28),
      );
      canvas.drawCircle(
        center,
        size.x * .45,
        Paint()..color = const Color(0xFFFEFDFA),
      );
      canvas.drawCircle(
        center,
        size.x * .35,
        Paint()..color = const Color(0xFFFFE3DC),
      );
    }
    canvas.restore();

    final painter = TextPainter(
      text: TextSpan(
        text: '${_displayedScore.round()}%',
        style: const TextStyle(
          color: Color(0xFF31566B),
          fontFamily: AppFonts.fredoka,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset((size.x - painter.width) / 2, (size.y - painter.height) / 2),
    );
  }
}
