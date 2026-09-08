import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primary,
      secondary: Color(0xFF00F5A0),
      surface: Color(0xFF131830),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.white,
    );

    final baseDark = ThemeData.dark();
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(baseDark.textTheme).copyWith(
      titleLarge: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        color: Colors.white.withValues(alpha: 0.85),
        fontSize: 13.5,
        height: 1.35,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        color: Colors.white.withValues(alpha: 0.6),
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0A0D1A),
      colorScheme: colorScheme,
      cardColor: const Color(0xFF131830),
      dividerColor: Colors.white.withValues(alpha: 0.08),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0A0D1A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0F1326),
        selectedItemColor: Color(0xFF00F5A0),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF131830),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
