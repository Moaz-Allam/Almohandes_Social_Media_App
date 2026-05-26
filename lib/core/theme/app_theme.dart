import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

/// Application theme mirroring the web dashboard design system.
///
/// Web reference (index.css):
///  - radius: 1.25rem (~20px)
///  - dark bg: HSL(240 10% 3%), card: HSL(240 10% 6%), border: HSL(240 5% 15%)
///  - light bg: white, card: white, border: HSL(214 32% 91%)
///  - primary (light): HSL(221 83% 53%), primary (dark): HSL(217 91% 60%)
///  - Arabic font: IBM Plex Sans Arabic / Cairo
abstract final class AppTheme {
  static const double radius = 20.0;
  static const double radiusSm = 12.0;
  static const double radiusLg = 24.0;

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.white,
      cardColor: AppColors.white,
      dividerColor: AppColors.borderLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: AppColors.white,
        onPrimary: AppColors.white,
        onSurface: AppColors.inkLight,
        error: AppColors.destructive,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
      primaryTextTheme: GoogleFonts.cairoTextTheme(base.primaryTextTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.inkLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: AppColors.borderLight),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkLight,
          side: const BorderSide(color: AppColors.borderLight),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAltLight,
        hintStyle: TextStyle(
          color: AppColors.mutedLight.withValues(alpha: .65),
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedLight,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.inkLight),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAltLight,
        selectedColor: AppColors.primary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        side: const BorderSide(color: AppColors.borderLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      cardColor: AppColors.surfaceDark,
      dividerColor: AppColors.borderDark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.primaryGlow,
        primary: AppColors.primaryGlow,
        secondary: AppColors.surfaceAltDark,
        surface: AppColors.surfaceDark,
        onPrimary: AppColors.backgroundDark,
        onSurface: AppColors.inkDark,
        error: AppColors.destructive,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme),
      primaryTextTheme: GoogleFonts.cairoTextTheme(base.primaryTextTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.inkDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: AppColors.borderDark.withValues(alpha: 0.6)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primaryGlow,
          foregroundColor: AppColors.white,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkDark,
          side: BorderSide(color: AppColors.borderDark.withValues(alpha: 0.8)),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryGlow,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAltDark,
        hintStyle: TextStyle(
          color: AppColors.mutedDark.withValues(alpha: .65),
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: AppColors.borderDark.withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide(color: AppColors.borderDark.withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: AppColors.primaryGlow, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryGlow,
        unselectedItemColor: AppColors.mutedDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.borderDark.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.inkDark),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAltDark,
        selectedColor: AppColors.primaryGlow,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        side: BorderSide(color: AppColors.borderDark.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

/// Context extensions that resolve the right palette entry for the active
/// theme. Use these instead of hard-coding colors inside widgets so light/dark
/// stays consistent across the app.
extension AppThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground => isDarkMode ? AppColors.backgroundDark : AppColors.white;

  Color get appSurface => isDarkMode ? AppColors.surfaceDark : AppColors.white;

  Color get appSurfaceAlt =>
      isDarkMode ? AppColors.surfaceAltDark : AppColors.surfaceLight;

  Color get appSoft => isDarkMode ? AppColors.softDark : AppColors.softLight;

  Color get appText => isDarkMode ? AppColors.inkDark : AppColors.inkLight;

  Color get appMuted => isDarkMode ? AppColors.mutedDark : AppColors.mutedLight;

  Color get appBorder => isDarkMode ? AppColors.borderDark : AppColors.borderLight;

  /// Primary brand color appropriate for the active theme — slightly brighter
  /// in dark mode to match the web app's HSL(217 91% 60%).
  Color get appPrimary => isDarkMode ? AppColors.primaryGlow : AppColors.primary;

  Color get appPaleBlue => isDarkMode
      ? AppColors.primaryGlow.withValues(alpha: 0.12)
      : const Color(0xFFE0EAFF);
}
