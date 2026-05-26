import 'package:flutter/material.dart';

/// Color tokens mirroring the web dashboard's design system.
///
/// Light mode uses near-white surfaces with a professional indigo-blue primary
/// (HSL 221 83% 53%). Dark mode uses Vercel/Linear-style deep neutrals
/// (HSL 240 10% 3%) with the brighter blue (HSL 217 91% 60%).
abstract final class AppColors {
  // Primary blue (light: 221 83% 53%, dark variant uses primaryGlow)
  static const primary = Color(0xFF2563EB);
  static const primaryGlow = Color(0xFF3B82F6); // brighter blue used in dark
  static const primaryDark = Color(0xFF1D4ED8);

  // Neutrals
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);

  // Light surfaces (foreground 222 47% 11%, muted 214 32% 96%, border 214 32% 91%)
  static const inkLight = Color(0xFF0F172A);
  static const mutedLight = Color(0xFF64748B);
  static const surfaceLight = Color(0xFFF1F5F9);
  static const surfaceAltLight = Color(0xFFF8FAFC);
  static const borderLight = Color(0xFFE2E8F0);
  static const softLight = Color(0xFFF5F7FA);

  // Dark surfaces (Vercel/Linear neutral dark)
  static const inkDark = Color(0xFFFAFAFA);
  static const mutedDark = Color(0xFFA1A1AA);
  static const backgroundDark = Color(0xFF09090B);    // HSL 240 10% 3%
  static const surfaceDark = Color(0xFF111114);       // HSL 240 10% 6%
  static const surfaceAltDark = Color(0xFF1A1A1F);    // HSL 240 5% 12%
  static const borderDark = Color(0xFF26262C);        // HSL 240 5% 15%
  static const softDark = Color(0xFF050507);

  // Status colors (mirrors success/warning/destructive in web app)
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const destructive = Color(0xFFEF4444);
  static const purpleAccent = Color(0xFF8B5CF6);
  static const cyanAccent = Color(0xFF06B6D4);
  static const roseAccent = Color(0xFFF43F5E);

  // Legacy aliases kept so existing references keep compiling. They route to
  // the equivalent token in the new palette (light defaults — context.app* in
  // app_theme.dart already swaps the right one in for dark mode).
  static const blue = primary;
  static const darkBlue = primaryDark;
  static const navy = primaryDark;
  static const ink = inkLight;
  static const muted = mutedLight;
  static const graphite = mutedLight;
  static const soft = softLight;
  static const canvas = softLight;
  static const paleBlue = surfaceLight;
  static const surface = surfaceLight;
  static const surfaceAlt = surfaceAltLight;
  static const border = borderLight;
  static const line = borderLight;
  static const green = success;
}
