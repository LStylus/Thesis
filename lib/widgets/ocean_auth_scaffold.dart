import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/constants/app_assets.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_text_styles.dart';

double _clampDouble(double value, double min, double max) {
  return value.clamp(min, max).toDouble();
}

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
                  final keyboardInset = mediaQuery.viewInsets.bottom;
                  final effectiveHorizontalPadding = _clampDouble(
                    safeConstraints.maxWidth * 0.055,
                    AppSpacing.compactPageHorizontalPadding,
                    math.max(
                      AppSpacing.compactPageHorizontalPadding,
                      horizontalPadding * 2,
                    ),
                  );
                  final verticalPadding = _clampDouble(
                    safeConstraints.maxHeight * 0.052,
                    16,
                    36,
                  );
                  final paneGap = _clampDouble(
                    safeConstraints.maxWidth * 0.035,
                    20,
                    48,
                  );
                  final paneHeight = math.max(
                    360.0,
                    safeConstraints.maxHeight -
                        (verticalPadding * 2) -
                        keyboardInset,
                  );
                  final contentTopPadding = _clampDouble(topSpacing, 10, 32);
                  final contentBottomPadding = _clampDouble(
                    bottomPadding,
                    18,
                    42,
                  );

                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      effectiveHorizontalPadding,
                      verticalPadding,
                      effectiveHorizontalPadding,
                      verticalPadding + bottomSafeInset,
                    ),
                    child: SizedBox(
                      height: paneHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 5,
                            child: _LandscapeAuthBrandPanel(
                              showMascot: showMascot,
                              mascotWidth: mascotWidth,
                              mascotHeight: mascotHeight,
                              showSandDecoration: showSandDecoration,
                            ),
                          ),
                          SizedBox(width: paneGap),
                          Expanded(
                            flex: 4,
                            child: _LandscapeAuthContentPane(
                              height: paneHeight,
                              topPadding: contentTopPadding,
                              bottomPadding: contentBottomPadding,
                              children: children,
                            ),
                          ),
                        ],
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

class _LandscapeAuthContentPane extends StatelessWidget {
  final List<Widget> children;
  final double height;
  final double topPadding;
  final double bottomPadding;

  const _LandscapeAuthContentPane({
    required this.children,
    required this.height,
    required this.topPadding,
    required this.bottomPadding,
  });

  @override
  Widget build(BuildContext context) {
    final minContentHeight = math.max(0.0, height - topPadding - bottomPadding);

    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(0, topPadding, 0, bottomPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minContentHeight),
            child: Align(
              alignment: Alignment.center,
              child: Column(mainAxisSize: MainAxisSize.min, children: children),
            ),
          ),
        ),
      ),
    );
  }
}

class _LandscapeAuthBrandPanel extends StatelessWidget {
  final bool showMascot;
  final double mascotWidth;
  final double mascotHeight;
  final bool showSandDecoration;

  const _LandscapeAuthBrandPanel({
    required this.showMascot,
    required this.mascotWidth,
    required this.mascotHeight,
    required this.showSandDecoration,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: ColoredBox(
        color: showSandDecoration ? AppColors.infoBackground : Colors.white,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _LandscapeBrandPainter(
                  showSandDecoration: showSandDecoration,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final whaleScale = _clampDouble(
                    constraints.maxHeight / 460,
                    0.68,
                    1,
                  );
                  final titleSize = _clampDouble(
                    constraints.maxWidth * 0.12,
                    34,
                    54,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'VOICE VOYAGE',
                          style: AppTextStyles.appTitle.copyWith(
                            fontSize: titleSize,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Speech sound adventure',
                        style: AppTextStyles.subtitle.copyWith(
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (showMascot)
                        Center(
                          child: FigmaWhaleMascot(
                            width: mascotWidth * whaleScale,
                            height: mascotHeight * whaleScale,
                          ),
                        ),
                      const Spacer(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandscapeBrandPainter extends CustomPainter {
  final bool showSandDecoration;

  const _LandscapeBrandPainter({required this.showSandDecoration});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;

    paint.color = AppColors.primary.withValues(alpha: 0.1);
    final wave = Path()
      ..moveTo(0, size.height * 0.22)
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.08,
        size.width * 0.48,
        size.height * 0.36,
        size.width,
        size.height * 0.16,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(wave, paint);

    if (!showSandDecoration) return;

    paint.color = AppColors.sand.withValues(alpha: 0.96);
    final sand = Path()
      ..moveTo(0, size.height * 0.72)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.66,
        size.width * 0.44,
        size.height * 0.82,
        size.width,
        size.height * 0.72,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(sand, paint);

    paint.color = AppColors.coral.withValues(alpha: 0.72);
    final star = Path();
    final center = Offset(size.width * 0.85, size.height * 0.86);
    const outer = 22.0;
    const inner = 9.5;
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
  bool shouldRepaint(covariant _LandscapeBrandPainter oldDelegate) {
    return oldDelegate.showSandDecoration != showSandDecoration;
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
        AppAssets.childExplorer,
        fit: BoxFit.contain,
        semanticsLabel: 'Voice Voyage child explorer',
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
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FBFC),
      constraints: const BoxConstraints(minHeight: AppSpacing.fieldHeight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 21),
      hintStyle: AppTextStyles.fieldHint,
      labelStyle: AppTextStyles.fieldHint.copyWith(fontSize: 14),
      floatingLabelStyle: AppTextStyles.fieldHint.copyWith(
        color: AppColors.primaryShadow,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      prefixIconColor: const Color(0xFF6E8995),
      suffixIconColor: const Color(0xFF6E8995),
      border: _border(const Color(0xFFDCE8EC)),
      enabledBorder: _border(const Color(0xFFDCE8EC)),
      focusedBorder: _border(AppColors.primary, width: 1.8),
      errorBorder: _border(AppColors.error),
      focusedErrorBorder: _border(AppColors.error, width: 1.8),
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
      child: IgnorePointer(child: CustomPaint(painter: _SandPainter())),
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
