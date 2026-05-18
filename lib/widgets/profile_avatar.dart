import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';
import '../core/constants/profile_assets.dart';

class ProfileAvatar extends StatelessWidget {
  final String assetPath;
  final String fallbackSeed;
  final double size;
  final double borderWidth;
  final double borderRadius;
  final Color borderColor;
  final List<BoxShadow> boxShadow;

  const ProfileAvatar({
    super.key,
    required this.assetPath,
    required this.fallbackSeed,
    this.size = 52,
    this.borderWidth = 2,
    this.borderRadius = 10,
    this.borderColor = Colors.white,
    this.boxShadow = const [],
  });

  @override
  Widget build(BuildContext context) {
    final resolvedAsset = assetPath.isNotEmpty
        ? assetPath
        : ProfileAssets.fallbackForId(fallbackSeed);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: boxShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: resolvedAsset.isEmpty
          ? _FallbackAvatar(seed: fallbackSeed)
          : Image.asset(
              resolvedAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _FallbackAvatar(seed: fallbackSeed),
            ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final String seed;

  const _FallbackAvatar({required this.seed});

  @override
  Widget build(BuildContext context) {
    final initial = seed.trim().isEmpty ? '?' : seed.trim()[0].toUpperCase();
    return ColoredBox(
      color: AppColors.primary.withValues(alpha: 0.16),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: AppColors.primary,
            fontFamily: AppFonts.fredokaOne,
            fontSize: 20,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
