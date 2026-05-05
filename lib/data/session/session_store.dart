import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SessionStore {
  Future<bool> isSignedIn();

  Future<bool> isDarkMode();

  Future<void> saveSignedIn();

  Future<void> saveDarkMode(bool enabled);

  Future<void> clear();
}

final class SharedPreferencesSessionStore implements SessionStore {
  static const _signedInKey = 'session.signedIn';
  static const _darkModeKey = 'settings.darkMode';

  @override
  Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_signedInKey) ?? false;
  }

  @override
  Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  @override
  Future<void> saveSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_signedInKey, true);
  }

  @override
  Future<void> saveDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, enabled);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_signedInKey);
  }
}
