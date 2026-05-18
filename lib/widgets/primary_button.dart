import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_fonts.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return Container(
      width: width,
      height: 69,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34.5),
        boxShadow: [
          BoxShadow(
            color: enabled ? const Color(0xFF009DD1) : const Color(0xFFB7B7B7),
            offset: const Offset(0, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: SizedBox(
        height: 65,
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
              borderRadius: BorderRadius.circular(32.5),
            ),
            textStyle: const TextStyle(
              fontFamily: AppFonts.fredoka,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
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
              : Text(text),
        ),
      ),
    );
  }
}
