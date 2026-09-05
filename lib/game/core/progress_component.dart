import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';

class ProgressComponent extends PositionComponent {
  String _text = '';

  ProgressComponent() : super(anchor: Anchor.topRight, priority: 30);

  void setProgress(String text) {
    _text = text;
  }

  void layoutFor(Vector2 gameSize) {
    size = Vector2(120, 38);
    position = Vector2(gameSize.x - 22, 18);
  }

  @override
  void render(Canvas canvas) {
    if (_text.trim().isEmpty) return;

    final rect = Offset.zero & Size(size.x, size.y);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final fill = Paint()
      ..color = Colors.white.withValues(alpha: 0.94)
      ..isAntiAlias = true;
    final pill = RRect.fromRectAndRadius(rect, const Radius.circular(999));
    canvas.drawRRect(pill.shift(const Offset(0, 4)), shadowPaint);
    canvas.drawRRect(pill, fill);

    final painter = TextPainter(
      text: TextSpan(
        text: _text,
        style: const TextStyle(
          color: AppColors.primary,
          fontFamily: AppFonts.fredoka,
          fontSize: 14,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: size.x - 20);
    painter.paint(
      canvas,
      Offset((size.x - painter.width) / 2, (size.y - painter.height) / 2),
    );
  }
}
