import 'package:flutter/material.dart';

import '../core/constants/app_assets.dart';

class CountdownMicButton extends StatelessWidget {
  final String assetPath;
  final String label;
  final double progress;
  final bool showRing;
  final bool isIndeterminate;
  final double size;
  final VoidCallback? onTap;

  const CountdownMicButton({
    super.key,
    this.assetPath = AppAssets.microphoneButton,
    required this.label,
    required this.progress,
    required this.showRing,
    this.isIndeterminate = false,
    this.size = 72,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outerSize = size + 20;
    final ringValue = showRing && !isIndeterminate
        ? progress.clamp(0.0, 1.0).toDouble()
        : null;

    return Semantics(
      label: label,
      button: true,
      enabled: onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: outerSize,
          height: outerSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: outerSize - 2,
                height: outerSize - 2,
                decoration: BoxDecoration(
                  color: showRing
                      ? const Color(0x5537D9F7)
                      : Colors.white.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                  boxShadow: showRing
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF1ABCE8,
                            ).withValues(alpha: 0.42),
                            blurRadius: 13,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : const [],
                ),
              ),
              if (showRing)
                SizedBox(
                  width: outerSize - 1,
                  height: outerSize - 1,
                  child: CircularProgressIndicator(
                    value: ringValue,
                    strokeWidth: 5.5,
                    strokeCap: StrokeCap.round,
                    color: const Color(0xFF23C7F2),
                    backgroundColor: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              SizedBox(
                width: size,
                height: size,
                child: Image.asset(assetPath, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
