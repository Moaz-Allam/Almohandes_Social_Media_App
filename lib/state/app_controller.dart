import 'package:flutter/foundation.dart';

import '../data/session/session_store.dart';
import '../models/app_tab.dart';
import '../models/profile_form.dart';

final class AppController extends ChangeNotifier {
  AppController({required SessionStore sessionStore})
    : _sessionStore = sessionStore;

  final SessionStore _sessionStore;

  bool _isBootstrapped = false;
  bool _isSignedIn = false;
  AppTab _selectedTab = AppTab.feed;
  ProfileForm? _profile;

  bool get isBootstrapped => _isBootstrapped;

  bool get isSignedIn => _isSignedIn;

  AppTab get selectedTab => _selectedTab;

  ProfileForm? get profile => _profile;

  Future<void> bootstrap() async {
    _isSignedIn = await _sessionStore.isSignedIn();
    _isBootstrapped = true;
    notifyListeners();
  }

  Future<void> signIn() async {
    _isSignedIn = true;
    await _sessionStore.saveSignedIn();
    notifyListeners();
  }

  Future<void> completeSignUp(ProfileForm profile) async {
    _profile = profile;
    _isSignedIn = true;
    await _sessionStore.saveSignedIn();
    notifyListeners();
  }

  Future<void> signOut() async {
    _isSignedIn = false;
    _profile = null;
    _selectedTab = AppTab.feed;
    await _sessionStore.clear();
    notifyListeners();
  }

  void selectTab(AppTab tab) {
    if (_selectedTab == tab) {
      return;
    }
    _selectedTab = tab;
    notifyListeners();
  }
}
