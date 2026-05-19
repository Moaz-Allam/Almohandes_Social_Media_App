import 'package:flutter/material.dart';

/// User's theme preference.
///
/// - [system] — track the OS theme (default for new installs).
/// - [light] — force the light theme regardless of OS.
/// - [dark]  — force the dark theme regardless of OS.
enum AppThemeMode {
  system,
  light,
  dark;

  ThemeMode get materialMode => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };

  /// Whether dark colors should be shown, given the OS brightness.
  bool isDark(Brightness platformBrightness) {
    return switch (this) {
      AppThemeMode.dark => true,
      AppThemeMode.light => false,
      AppThemeMode.system => platformBrightness == Brightness.dark,
    };
  }

  String get storageValue => name;

  static AppThemeMode fromStorageValue(String? value) {
    return switch (value) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }
}
