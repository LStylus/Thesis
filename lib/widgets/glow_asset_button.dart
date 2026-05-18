import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class GlowAssetButton extends StatelessWidget {
  final String assetPath;
  final String semanticsLabel;
  final VoidCallback? onTap;
  final bool isActive;
  final double size;
  final double glowBlur;
  final double glowSpread;

  const GlowAssetButton({
    super.key,
    required this.assetPath,
    required this.semanticsLabel,
    required this.onTap,
    this.isActive = false,
    this.size = 68,
    this.glowBlur = 22,
    this.glowSpread = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.56),
                      blurRadius: glowBlur,
                      spreadRadius: glowSpread,
                    ),
                  ]
                : const [],
          ),
          child: Opacity(
            opacity: onTap == null ? 0.45 : 1,
            child: SizedBox(
              width: size,
              height: size,
              child: Image.asset(assetPath, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}
