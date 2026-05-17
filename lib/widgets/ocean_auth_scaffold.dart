import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class OceanAuthScaffold extends StatelessWidget {
  final List<Widget> children;
  final double topSpacing;
  final bool showMascot;
  final double mascotWidth;
  final double mascotHeight;
  final double bottomPadding;
  final Widget? leading;

  const OceanAuthScaffold({
    super.key,
    required this.children,
    this.topSpacing = 132,
    this.showMascot = true,
    this.mascotWidth = 304,
    this.mascotHeight = 170,
    this.bottomPadding = 154,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Colors.white)),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 126,
            child: IgnorePointer(child: CustomPaint(painter: _SandPainter())),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = math.min(
                  math.max(0.0, constraints.maxWidth - 56),
                  356.0,
                );

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(28, 0, 28, bottomPadding),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        children: [
                          SizedBox(height: topSpacing),
                          if (showMascot) ...[
                            FigmaWhaleMascot(
                              width: mascotWidth,
                              height: mascotHeight,
                            ),
                            const SizedBox(height: 16),
                          ],
                          ...children,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (leading != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 10),
                child: leading,
              ),
            ),
        ],
      ),
    );
  }
}

class FigmaWhaleMascot extends StatelessWidget {
  final double width;
  final double height;

  const FigmaWhaleMascot({super.key, this.width = 304, this.height = 170});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const CustomPaint(painter: _WhalePainter()),
    );
  }
}

class OceanAuthTextStyles {
  static const TextStyle title = TextStyle(
    color: AppColors.primary,
    fontSize: 32,
    fontWeight: FontWeight.w900,
    height: 1.22,
    letterSpacing: 0,
  );

  static const TextStyle subtitle = TextStyle(
    color: AppColors.textGray,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: 0,
  );

  static const TextStyle link = TextStyle(
    color: AppColors.textGray,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
    letterSpacing: 0,
  );
}

class OceanFormStyles {
  static InputDecoration inputDecoration(
    String hintText, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 21),
      hintStyle: const TextStyle(
        color: AppColors.textGray,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      border: _border(AppColors.borderGray),
      enabledBorder: _border(AppColors.borderGray),
      focusedBorder: _border(AppColors.primary, width: 1.4),
      errorBorder: _border(AppColors.error),
      focusedErrorBorder: _border(AppColors.error, width: 1.4),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _WhalePainter extends CustomPainter {
  const _WhalePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final blue = AppColors.primary;
    final w = size.width;
    final h = size.height;
    final sx = w / 304;
    final sy = h / 170;

    Offset p(double x, double y) => Offset(x * sx, y * sy);

    paint.color = blue;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(45 * sx, 34 * sy, 214 * sx, 86 * sy),
      Radius.circular(48 * sx),
    );
    canvas.drawRRect(body, paint);

    final leftFin = Path()
      ..moveTo(48 * sx, 82 * sy)
      ..cubicTo(9 * sx, 79 * sy, 0, 90 * sy, 16 * sx, 109 * sy)
      ..cubicTo(36 * sx, 132 * sy, 65 * sx, 118 * sy, 82 * sx, 94 * sy)
      ..cubicTo(73 * sx, 87 * sy, 62 * sx, 84 * sy, 48 * sx, 82 * sy)
      ..close();
    canvas.drawPath(leftFin, paint);

    final rightFin = Path()
      ..moveTo(256 * sx, 82 * sy)
      ..cubicTo(295 * sx, 79 * sy, 304 * sx, 90 * sy, 288 * sx, 109 * sy)
      ..cubicTo(268 * sx, 132 * sy, 239 * sx, 118 * sy, 222 * sx, 94 * sy)
      ..cubicTo(231 * sx, 87 * sy, 242 * sx, 84 * sy, 256 * sx, 82 * sy)
      ..close();
    canvas.drawPath(rightFin, paint);

    paint.color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(74 * sx, 84 * sy, 156 * sx, 55 * sy),
        Radius.circular(32 * sx),
      ),
      paint,
    );

    paint.color = blue;
    canvas.drawOval(Rect.fromLTWH(107 * sx, 105 * sy, 90 * sx, 48 * sy), paint);

    _drawEye(canvas, p(86, 56), sx, sy);
    _drawEye(canvas, p(226, 56), sx, sy);
  }

  void _drawEye(Canvas canvas, Offset center, double sx, double sy) {
    final paint = Paint()..isAntiAlias = true;
    paint.color = Colors.white;
    canvas.drawCircle(center, 14 * sx, paint);

    paint.color = AppColors.primary;
    canvas.drawCircle(
      Offset(center.dx + 3 * sx, center.dy - 2 * sy),
      10 * sx,
      paint,
    );

    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(center.dx - 5 * sx, center.dy - 7 * sy),
      5 * sx,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SandPainter extends CustomPainter {
  const _SandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    paint.color = const Color(0xFFFFE891);
    final sand = Path()
      ..moveTo(0, size.height * 0.35)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.52,
        size.width * 0.54,
        size.height * 0.14,
        size.width,
        size.height * 0.12,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(sand, paint);

    paint.color = const Color(0xFFF6D765);
    canvas.save();
    canvas.translate(size.width * 0.1, size.height * 0.82);
    canvas.rotate(0.2);
    canvas.drawOval(const Rect.fromLTWH(-14, -8, 28, 16), paint);
    canvas.restore();

    canvas.save();
    canvas.translate(size.width * 0.45, size.height * 0.52);
    canvas.rotate(-0.18);
    canvas.drawOval(const Rect.fromLTWH(-26, -10, 52, 20), paint);
    canvas.restore();

    paint.color = const Color(0xFFFF8658);
    final star = Path();
    final center = Offset(size.width * 0.91, size.height * 0.72);
    const outer = 31.0;
    const inner = 14.0;
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? outer : inner;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    canvas.drawPath(star, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
