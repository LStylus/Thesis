import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

class AppTextStyles {
  static const TextStyle appTitle = TextStyle(
    color: AppColors.primary,
    fontFamily: AppFonts.matemasie,
    fontSize: 50,
    fontWeight: FontWeight.w400,
    height: 1.06,
    letterSpacing: 0,
  );

  static const TextStyle pageTitle = TextStyle(
    color: AppColors.primary,
    fontFamily: AppFonts.fredokaOne,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.14,
    letterSpacing: 0,
  );

  static const TextStyle screeningTitle = TextStyle(
    color: AppColors.primary,
    fontFamily: AppFonts.fredokaOne,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.06,
    letterSpacing: 0,
  );

  static const TextStyle subtitle = TextStyle(
    color: AppColors.softTextGray,
    fontFamily: AppFonts.fredoka,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: 0,
  );

  static const TextStyle helper = TextStyle(
    color: AppColors.textGray,
    fontFamily: AppFonts.fredoka,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.18,
    letterSpacing: 0,
  );

  static const TextStyle field = TextStyle(
    color: Colors.black87,
    fontFamily: AppFonts.fredoka,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle fieldHint = TextStyle(
    color: AppColors.textGray,
    fontFamily: AppFonts.fredoka,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  );

  static const TextStyle button = TextStyle(
    color: Colors.white,
    fontFamily: AppFonts.fredoka,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static const TextStyle link = TextStyle(
    color: AppColors.textGray,
    fontFamily: AppFonts.fredoka,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    decoration: TextDecoration.underline,
    letterSpacing: 0,
  );
}
