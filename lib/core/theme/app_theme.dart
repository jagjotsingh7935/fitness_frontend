import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.card,
      onPrimary: AppColors.text,
      onSecondary: AppColors.text,
      onSurface: AppColors.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: colorScheme,
      cardColor: AppColors.card,
      dividerColor: AppColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0xFFBDBDBD),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: AppColors.text,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: AppColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: AppColors.text,
          fontSize: 14,
          height: 1.3,
        ),
      ),
    );
  }
}

