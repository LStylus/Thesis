import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_text_styles.dart';

class OceanAuthScaffold extends StatelessWidget {
  final List<Widget> children;
  final double topSpacing;
  final bool showMascot;
  final double mascotWidth;
  final double mascotHeight;
  final double bottomPadding;
  final double sandBottomExtension;
  final Widget? leading;
  final double horizontalPadding;
  final bool showSandDecoration;

  const OceanAuthScaffold({
    super.key,
    required this.children,
    this.topSpacing = AppSpacing.authTopSpacing,
    this.showMascot = true,
    this.mascotWidth = AppSpacing.mascotWidth,
    this.mascotHeight = AppSpacing.mascotHeight,
    this.bottomPadding = AppSpacing.bottomContentPadding,
    this.sandBottomExtension = 0,
    this.leading,
    this.horizontalPadding = AppSpacing.pageHorizontalPadding,
    this.showSandDecoration = true,
  });

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomSafeInset = math.max(
      mediaQuery.viewPadding.bottom,
      mediaQuery.padding.bottom,
    );
    final bottomFillHeight = showSandDecoration
        ? AppSpacing.sandHeight + sandBottomExtension + bottomSafeInset
        : 0.0;
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: showSandDecoration
          ? AppColors.sand
          : Colors.white,
      systemNavigationBarDividerColor: showSandDecoration
          ? AppColors.sand
          : Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );

    SystemChrome.setSystemUIOverlayStyle(overlayStyle);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: showSandDecoration ? AppColors.sand : Colors.white,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Colors.white)),
            if (showSandDecoration)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: bottomFillHeight,
                child: const BottomSandDecoration(),
              ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, safeConstraints) {
                  final isCompactHeight = safeConstraints.maxHeight < 700;
                  final isNarrow = safeConstraints.maxWidth < 360;
                  final effectiveTopSpacing = math.max(
                    34.0,
                    topSpacing * (isCompactHeight ? 0.72 : 1.0),
                  );
                  final effectiveHorizontalPadding = isNarrow
                      ? AppSpacing.compactPageHorizontalPadding
                      : horizontalPadding;
                  final contentWidth = math.min(
                    math.max(
                      0.0,
                      safeConstraints.maxWidth -
                          (effectiveHorizontalPadding * 2),
                    ),
                    AppSpacing.contentMaxWidth,
                  );
                  final keyboardInset = mediaQuery.viewInsets.bottom;
                  final effectiveBottomPadding =
                      bottomPadding + bottomSafeInset + keyboardInset;

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      effectiveHorizontalPadding,
                      0,
                      effectiveHorizontalPadding,
                      effectiveBottomPadding,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: contentWidth,
                        child: Column(
                          children: [
                            SizedBox(height: effectiveTopSpacing),
                            if (showMascot) ...[
                              FigmaWhaleMascot(
                                width: mascotWidth,
                                height: mascotHeight,
                              ),
                              const SizedBox(height: AppSpacing.gapMd),
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
      ),
    );
  }
}

class FigmaWhaleMascot extends StatelessWidget {
  final double width;
  final double height;

  const FigmaWhaleMascot({
    super.key,
    this.width = AppSpacing.mascotWidth,
    this.height = AppSpacing.mascotHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(
        AppAssets.whaleMascot,
        fit: BoxFit.contain,
        semanticsLabel: 'Voice Voyage whale mascot',
      ),
    );
  }
}

class OceanBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const OceanBackButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Back',
      button: true,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        color: const Color(0xFFC3C3C3),
        iconSize: 26,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      ),
    );
  }
}

class OceanCloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const OceanCloseButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Close',
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFD7D7D7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class OceanAuthTextStyles {
  static const TextStyle title = AppTextStyles.pageTitle;

  static const TextStyle subtitle = AppTextStyles.subtitle;

  static const TextStyle link = AppTextStyles.link;
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
      constraints: const BoxConstraints(minHeight: AppSpacing.fieldHeight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 21),
      hintStyle: AppTextStyles.fieldHint,
      border: _border(AppColors.borderGray),
      enabledBorder: _border(AppColors.borderGray),
      focusedBorder: _border(AppColors.primary, width: 1.4),
      errorBorder: _border(AppColors.error),
      focusedErrorBorder: _border(AppColors.error, width: 1.4),
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class BottomSandDecoration extends StatelessWidget {
  const BottomSandDecoration({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: IgnorePointer(
        child: CustomPaint(painter: _SandPainter()),
      ),
    );
  }
}

class _SandPainter extends CustomPainter {
  const _SandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    paint.color = AppColors.sand;
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

    paint.color = AppColors.sandAccent;
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

    paint.color = AppColors.coral;
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
