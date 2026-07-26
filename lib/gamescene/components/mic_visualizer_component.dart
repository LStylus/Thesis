import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_fonts.dart';
import '../game_scene.dart';
import '../game_scene_state.dart';

class MicVisualizerComponent extends PositionComponent
    with HasGameReference<GameScene> {
  GameSceneState _state = GameSceneState.initial();
  double _time = 0;
  ui.Image? _microphoneImage;

  MicVisualizerComponent() : super(anchor: Anchor.center, priority: 28);

  @override
  Future<void> onLoad() async {
    _microphoneImage = await game.images.load(AppAssets.microphoneButtonFile);
  }

  void sync(GameSceneState state) {
    _state = state;
  }

  void layoutFor(Vector2 gameSize) {
    final visualSize = (gameSize.y * 0.20).clamp(88.0, 112.0).toDouble();
    size = Vector2.all(visualSize);
    position = Vector2(gameSize.x * 0.5, gameSize.y - visualSize * 0.52 - 14);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (_state.phase == GamePhase.completed) return;

    final center = Offset(size.x / 2, size.y / 2);
    final recording = _state.phase == GamePhase.recording;
    final checking = _state.phase == GamePhase.processing;
    final radius = size.x * 0.28;
    if (recording) {
      final pulsePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..isAntiAlias = true;
      for (var i = 0; i < 3; i++) {
        final t = (_time * 1.8 + i / 3) % 1;
        pulsePaint.color = AppColors.primary.withValues(alpha: 0.34 * (1 - t));
        canvas.drawCircle(center, radius + t * size.x * 0.30, pulsePaint);
      }
    }

    final fill = Paint()
      ..color = checking
          ? const Color(0xFFFFF6DD)
          : recording
          ? Colors.white.withValues(alpha: 0.96)
          : const Color(0xFFDDE2E6)
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius + 8, fill);

    if (recording) {
      final baseRing = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary.withValues(alpha: 0.16);
      final progressRing = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.primary;
      final ringRect = Rect.fromCircle(center: center, radius: radius + 12);
      canvas.drawCircle(center, radius + 12, baseRing);
      canvas.drawArc(
        ringRect,
        -math.pi / 2,
        math.pi * 2 * _state.micProgress.clamp(0.0, 1.0),
        false,
        progressRing,
      );
    } else if (checking) {
      final dotPaint = Paint()..isAntiAlias = true;
      for (var i = 0; i < 6; i++) {
        final wave = (_time * 1.6 + i / 6) % 1;
        final angle = -math.pi / 2 + i * math.pi / 3;
        dotPaint.color = const Color(
          0xFFFFB547,
        ).withValues(alpha: 0.25 + 0.55 * math.sin(wave * math.pi).abs());
        canvas.drawCircle(
          Offset(
            center.dx + math.cos(angle) * (radius + 14),
            center.dy + math.sin(angle) * (radius + 14),
          ),
          3.4,
          dotPaint,
        );
      }
    }

    final microphoneImage = _microphoneImage;
    if (microphoneImage != null) {
      final sourceSize = Size(
        microphoneImage.width.toDouble(),
        microphoneImage.height.toDouble(),
      );
      final destinationBounds = Rect.fromCenter(
        center: center,
        width: radius * 2.08,
        height: radius * 2.08,
      );
      final fitted = applyBoxFit(
        BoxFit.contain,
        sourceSize,
        destinationBounds.size,
      );
      final source = Alignment.center.inscribe(
        fitted.source,
        Offset.zero & sourceSize,
      );
      final destination = Alignment.center.inscribe(
        fitted.destination,
        destinationBounds,
      );
      canvas.drawImageRect(
        microphoneImage,
        source,
        destination,
        Paint()..isAntiAlias = true,
      );
    }

    if (recording) {
      final countdown = TextPainter(
        text: TextSpan(
          text: '${_state.countdown}',
          style: const TextStyle(
            color: AppColors.primary,
            fontFamily: AppFonts.fredoka,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      countdown.paint(
        canvas,
        Offset((size.x - countdown.width) / 2, size.y - countdown.height),
      );
    }
  }
}
