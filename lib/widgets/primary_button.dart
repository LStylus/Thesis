import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import '../core/constants/app_text_styles.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;
  final double height;
  final double borderRadius;
  final IconData? trailingIcon;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = AppSpacing.buttonHeight,
    this.borderRadius = AppSpacing.buttonRadius,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Container(
      width: width,
      height: height + 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: enabled ? AppColors.primaryShadow : const Color(0xFFB7B7B7),
            offset: const Offset(0, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: SizedBox(
        height: height,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled
                ? AppColors.primary
                : const Color(0xFFD7D7D7),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFD7D7D7),
            disabledForegroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            textStyle: AppTextStyles.button,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : trailingIcon == null
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(text, textAlign: TextAlign.center),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(text, textAlign: TextAlign.center),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Icon(trailingIcon, size: 21),
                  ],
                ),
        ),
      ),
    );
  }
}
