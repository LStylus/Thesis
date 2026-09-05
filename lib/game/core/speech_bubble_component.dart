import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_fonts.dart';

class SpeechBubbleComponent extends PositionComponent {
  String _text = '';
  bool _isError = false;

  SpeechBubbleComponent() : super(anchor: Anchor.center, priority: 20);

  void setMessage(String text, {bool isError = false}) {
    _text = text;
    _isError = isError;
  }

  void layoutFor(Vector2 gameSize) {
    final width = (gameSize.x * 0.48).clamp(280.0, 520.0).toDouble();
    size = Vector2(width, 74);
    position = Vector2(gameSize.x * 0.5, gameSize.y * 0.17);
  }

  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & Size(size.x, size.y);
    final fill = Paint()
      ..color = Colors.white.withValues(alpha: 0.96)
      ..isAntiAlias = true;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final bubble = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(bubble.shift(const Offset(0, 6)), shadow);
    canvas.drawRRect(bubble, fill);

    final color = _isError ? AppColors.error : const Color(0xFF3F5F73);
    var fontSize = 18.0;
    late TextPainter painter;
    do {
      painter = TextPainter(
        text: TextSpan(
          text: _text,
          style: TextStyle(
            color: color,
            fontFamily: AppFonts.fredoka,
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            height: 1.08,
            letterSpacing: 0,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: size.x - 30);
      if (painter.didExceedMaxLines && fontSize > 13) {
        fontSize -= 1;
      } else {
        break;
      }
    } while (fontSize > 13);
    painter.paint(
      canvas,
      Offset((size.x - painter.width) / 2, (size.y - painter.height) / 2),
    );
  }
}
