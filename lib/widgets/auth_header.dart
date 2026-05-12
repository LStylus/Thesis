import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;

  const AuthHeader({
    super.key,
    required this.title,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (onBack != null)
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: const Color(0xFFC3C3C3),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
