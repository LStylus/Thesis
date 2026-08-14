import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../game_scene_state.dart';

class FeedbackEffectComponent extends PositionComponent {
  final math.Random _random = math.Random(7);
  final List<_FeedbackParticle> _particles = [];
  GamePhase _lastPhase = GamePhase.loading;

  FeedbackEffectComponent() : super(priority: 50);

  void sync(GameSceneState state) {
    if (state.phase == _lastPhase) return;
    _lastPhase = state.phase;

    if (state.phase == GamePhase.correct ||
        state.phase == GamePhase.completed) {
      _burst(success: true);
    } else if (state.phase == GamePhase.retry ||
        state.phase == GamePhase.invalidAudio) {
      _burst(success: false);
    }
  }

  void layoutFor(Vector2 gameSize) {
    size = gameSize;
  }

  void _burst({required bool success}) {
    final center = Offset(size.x * 0.5, size.y * 0.42);
    final count = success ? 34 : 18;
    for (var i = 0; i < count; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = success
          ? 90 + _random.nextDouble() * 170
          : 50 + _random.nextDouble() * 90;
      _particles.add(
        _FeedbackParticle(
          position: center,
          velocity: Offset(math.cos(angle) * speed, math.sin(angle) * speed),
          color: success
              ? _successColors[i % _successColors.length]
              : AppColors.error,
          radius: success ? 4 + _random.nextDouble() * 5 : 3.5,
          life: success ? 0.95 + _random.nextDouble() * 0.42 : 0.62,
          spin: (_random.nextDouble() - 0.5) * 7,
          isStar: success && i.isEven,
        ),
      );
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final particle in _particles) {
      particle.age += dt;
      particle.position += particle.velocity * dt;
      particle.velocity += Offset(0, 180 * dt);
      particle.rotation += particle.spin * dt;
    }
    _particles.removeWhere((particle) => particle.age >= particle.life);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..isAntiAlias = true;
    for (final particle in _particles) {
      final t = (particle.age / particle.life).clamp(0.0, 1.0);
      paint.color = particle.color.withValues(alpha: 1 - t);
      canvas.save();
      canvas.translate(particle.position.dx, particle.position.dy);
      canvas.rotate(particle.rotation);
      if (particle.isStar) {
        _drawStar(canvas, paint, particle.radius);
      } else {
        canvas.drawCircle(Offset.zero, particle.radius, paint);
      }
      canvas.restore();
    }
  }

  void _drawStar(Canvas canvas, Paint paint, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? radius * 1.7 : radius * 0.72;
      final point = Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }
}

const List<Color> _successColors = [
  Color(0xFFFFD229),
  Color(0xFFFF8A58),
  Color(0xFF66D4F1),
  Color(0xFF21B15F),
  Colors.white,
];

class _FeedbackParticle {
  Offset position;
  Offset velocity;
  final Color color;
  final double radius;
  final double life;
  final double spin;
  final bool isStar;
  double age = 0;
  double rotation = 0;

  _FeedbackParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.life,
    required this.spin,
    required this.isStar,
  });
}
