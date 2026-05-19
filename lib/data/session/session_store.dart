import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_theme_mode.dart';

abstract interface class SessionStore {
  Future<bool> isSignedIn();

  /// Legacy boolean accessor. New callers should use [getThemeMode].
  /// Returns true if the user explicitly chose dark, OR if they haven't
  /// chosen yet and the only persisted value is the old boolean = true.
  Future<bool> isDarkMode();

  Future<AppThemeMode> getThemeMode();

  Future<void> saveSignedIn();

  /// Legacy boolean writer. Equivalent to
  /// `saveThemeMode(value ? dark : light)`.
  Future<void> saveDarkMode(bool enabled);

  Future<void> saveThemeMode(AppThemeMode mode);

  Future<void> clear();
}

final class SharedPreferencesSessionStore implements SessionStore {
  static const _signedInKey = 'session.signedIn';
  static const _darkModeKey = 'settings.darkMode';
  static const _themeModeKey = 'settings.themeMode';

  @override
  Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_signedInKey) ?? false;
  }

  @override
  Future<bool> isDarkMode() async {
    final mode = await getThemeMode();
    return mode == AppThemeMode.dark;
  }

  @override
  Future<AppThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeModeKey);
    if (stored != null) {
      return AppThemeMode.fromStorageValue(stored);
    }
    // Migration: if an older build stored the boolean, honor it once.
    if (prefs.containsKey(_darkModeKey)) {
      final wasDark = prefs.getBool(_darkModeKey) ?? false;
      final migrated = wasDark ? AppThemeMode.dark : AppThemeMode.light;
      await prefs.setString(_themeModeKey, migrated.storageValue);
      return migrated;
    }
    return AppThemeMode.system;
  }

  @override
  Future<void> saveSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_signedInKey, true);
  }

  @override
  Future<void> saveDarkMode(bool enabled) async {
    await saveThemeMode(enabled ? AppThemeMode.dark : AppThemeMode.light);
  }

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.storageValue);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_signedInKey);
  }
}
