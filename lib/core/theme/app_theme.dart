import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_fonts.dart';
import '../constants/app_spacing.dart';

class AppTheme {
  static ThemeData get lightTheme {
    const baseTextTheme = TextTheme(
      bodyLarge: TextStyle(fontFamily: AppFonts.fredoka),
      bodyMedium: TextStyle(fontFamily: AppFonts.fredoka),
      bodySmall: TextStyle(fontFamily: AppFonts.fredoka),
      labelLarge: TextStyle(fontFamily: AppFonts.fredoka),
      labelMedium: TextStyle(fontFamily: AppFonts.fredoka),
      labelSmall: TextStyle(fontFamily: AppFonts.fredoka),
      titleLarge: TextStyle(fontFamily: AppFonts.fredokaOne),
      titleMedium: TextStyle(fontFamily: AppFonts.fredokaOne),
      titleSmall: TextStyle(fontFamily: AppFonts.fredokaOne),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFonts.fredoka,
      textTheme: baseTextTheme,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.fredokaOne,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
          ),
          textStyle: const TextStyle(
            fontFamily: AppFonts.fredoka,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          color: AppColors.hintGray,
          fontFamily: AppFonts.fredoka,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.borderGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.3),
        ),
      ),
    );
  }
}
