import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';

/// Draws supplied recording values without owning a recorder or game session.
class MicVisualizerComponent extends PositionComponent {
  bool recording = false;
  bool checking = false;
  bool visible = true;
  double micLevel = 0;
  double micProgress = 0;
  int countdown = 0;
  double _time = 0;

  /// Borrowed from the owning scene's asset cache; that owner disposes it.
  final ui.Image? microphoneImage;

  MicVisualizerComponent({this.microphoneImage})
    : super(anchor: Anchor.center, priority: 28);

  void layoutFor(Vector2 gameSize) {
    final visualSize = (gameSize.y * 0.20).clamp(72.0, 112.0).toDouble();
    size = Vector2.all(visualSize);
    position = Vector2(gameSize.x * 0.91, gameSize.y - visualSize * 0.52 - 14);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    if (!visible) return;

    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x * 0.28;
    if (recording) {
      final levelBoost = micLevel.clamp(0.0, 1.0) * size.x * .08;
      final pulsePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..isAntiAlias = true;
      for (var i = 0; i < 3; i++) {
        final t = (_time * 1.8 + i / 3) % 1;
        pulsePaint.color = AppColors.primary.withValues(alpha: 0.34 * (1 - t));
        canvas.drawCircle(
          center,
          radius + levelBoost + t * size.x * 0.30,
          pulsePaint,
        );
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
        math.pi * 2 * micProgress.clamp(0.0, 1.0),
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

    final microphoneImage = this.microphoneImage;
    if (microphoneImage != null) {
      final sourceSize = Size(
        microphoneImage.width.toDouble(),
        microphoneImage.height.toDouble(),
      );
      final destinationBounds = Rect.fromCenter(
        center: center,
        width:
            radius * (2.08 + (recording ? micLevel.clamp(0.0, 1.0) * .12 : 0)),
        height:
            radius * (2.08 + (recording ? micLevel.clamp(0.0, 1.0) * .12 : 0)),
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
      final badgeCenter = Offset(
        center.dx + radius * .72,
        center.dy + radius * .72,
      );
      canvas.drawCircle(
        badgeCenter,
        12,
        Paint()
          ..color = Colors.white
          ..isAntiAlias = true,
      );
      canvas.drawCircle(
        badgeCenter,
        12,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..isAntiAlias = true,
      );
      final countdownPainter = TextPainter(
        text: TextSpan(
          text: '$countdown',
          style: const TextStyle(
            color: AppColors.primary,
            fontFamily: AppFonts.fredoka,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      countdownPainter.paint(
        canvas,
        Offset(
          badgeCenter.dx - countdownPainter.width / 2,
          badgeCenter.dy - countdownPainter.height / 2,
        ),
      );
    }
  }
}
