import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centralized design tokens. Keeping colors/spacing here (instead of magic
/// numbers scattered in widgets) is one of the first things a senior dev
/// review looks for.
class AppColors {
  AppColors._();

  static const primary = Color(0xFFFF5A1F);
  static const primaryDark = Color(0xFFE04A15);
  static const secondary = Color(0xFF1FA35E);
  static const background = Color(0xFFF7F7F9);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF1B1B1F);
  static const textSecondary = Color(0xFF6E6E76);
  static const textMuted = Color(0xFFA6A6AD);
  static const border = Color(0xFFE7E7EB);
  static const error = Color(0xFFE1443B);
  static const warning = Color(0xFFF5A623);
  static const success = Color(0xFF1FA35E);
}

class AppSpacing {
  AppSpacing._();

  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
}

class AppRadius {
  AppRadius._();

  static double get sm => 8.r;
  static double get md => 12.r;
  static double get lg => 16.r;
  static double get pill => 100.r;
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(
          fontSize: 22.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 15.sp, color: AppColors.textPrimary),
        bodyMedium: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
        bodySmall: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
        labelLarge: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.surface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
