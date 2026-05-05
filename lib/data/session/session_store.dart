import 'package:shared_preferences/shared_preferences.dart';

abstract interface class SessionStore {
  Future<bool> isSignedIn();

  Future<void> saveSignedIn();

  Future<void> clear();
}

final class SharedPreferencesSessionStore implements SessionStore {
  static const _signedInKey = 'session.signedIn';

  @override
  Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_signedInKey) ?? false;
  }

  @override
  Future<void> saveSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_signedInKey, true);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_signedInKey);
  }
}
