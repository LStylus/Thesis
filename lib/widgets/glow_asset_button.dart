import 'package:flutter/material.dart';

class GlowAssetButton extends StatelessWidget {
  final String assetPath;
  final String semanticsLabel;
  final VoidCallback? onTap;
  final bool isActive;
  final double size;
  final double glowBlur;
  final double glowSpread;
  final double disabledOpacity;

  const GlowAssetButton({
    super.key,
    required this.assetPath,
    required this.semanticsLabel,
    required this.onTap,
    this.isActive = false,
    this.size = 68,
    this.glowBlur = 22,
    this.glowSpread = 2,
    this.disabledOpacity = 0.45,
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
                      color: const Color(0xFF64E7FF).withValues(alpha: 0.84),
                      blurRadius: glowBlur,
                      spreadRadius: glowSpread,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: glowBlur * 0.42,
                      spreadRadius: 0,
                    ),
                  ]
                : const [],
          ),
          child: Opacity(
            opacity: onTap == null && !isActive ? disabledOpacity : 1,
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
