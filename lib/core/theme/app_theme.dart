import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

abstract final class AppTheme {
  static const _darkBackground = Color(0xFF0B1220);
  static const _darkSurface = Color(0xFF111827);
  static const _darkSurfaceAlt = Color(0xFF172033);
  static const _darkBorder = Color(0xFF2D3748);
  static const _darkText = Color(0xFFF8FAFC);
  static const _darkMuted = Color(0xFFA8B3C7);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.cairoTextTheme(),
      primaryTextTheme: GoogleFonts.cairoTextTheme(),
      scaffoldBackgroundColor: AppColors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        primary: AppColors.blue,
        secondary: AppColors.darkBlue,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSurface: AppColors.ink,
      ),
      fontFamily: GoogleFonts.cairo().fontFamily,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      primaryTextTheme: GoogleFonts.cairoTextTheme(
        ThemeData.dark().primaryTextTheme,
      ),
      scaffoldBackgroundColor: _darkBackground,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.blue,
        primary: AppColors.blue,
        secondary: AppColors.surfaceAlt,
        surface: _darkSurface,
        onPrimary: AppColors.white,
        onSurface: _darkText,
      ),
      cardColor: _darkSurface,
      dividerColor: _darkBorder,
      fontFamily: GoogleFonts.cairo().fontFamily,
      appBarTheme: const AppBarTheme(
        backgroundColor: _darkSurface,
        foregroundColor: _darkText,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurfaceAlt,
        hintStyle: const TextStyle(color: _darkMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
      ),
    );
  }
}

extension AppThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground => Theme.of(this).scaffoldBackgroundColor;

  Color get appSurface => isDarkMode ? AppTheme._darkSurface : AppColors.white;

  Color get appSurfaceAlt =>
      isDarkMode ? AppTheme._darkSurfaceAlt : AppColors.surface;

  Color get appSoft => isDarkMode ? const Color(0xFF0F172A) : AppColors.soft;

  Color get appText => isDarkMode ? AppTheme._darkText : AppColors.ink;

  Color get appMuted => isDarkMode ? AppTheme._darkMuted : AppColors.muted;

  Color get appBorder => isDarkMode ? AppTheme._darkBorder : AppColors.border;

  Color get appPaleBlue =>
      isDarkMode ? const Color(0xFF061D3D) : AppColors.paleBlue;
}
