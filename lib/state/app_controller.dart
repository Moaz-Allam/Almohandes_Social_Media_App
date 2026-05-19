import 'package:flutter/foundation.dart';

import '../data/repositories/app_repositories.dart';
import '../data/session/session_store.dart';
import '../models/account_type.dart';
import '../models/app_tab.dart';
import '../models/app_theme_mode.dart';
import '../models/profile_form.dart';
import '../models/saved_content.dart';

final class AppController extends ChangeNotifier {
  AppController({
    required SessionStore sessionStore,
    required this.repositories,
  }) : _sessionStore = sessionStore,
       super();

  final SessionStore _sessionStore;
  final AppRepositories repositories;

  bool _isBootstrapped = false;
  bool _isSignedIn = false;
  AppThemeMode _themeMode = AppThemeMode.system;
  // Exposed separately so the MaterialApp can subscribe ONLY to theme
  // changes without rebuilding on every unrelated notify (likes, messages,
  // notifications, …).
  late final ValueNotifier<AppThemeMode> themeModeListenable =
      ValueNotifier<AppThemeMode>(_themeMode);
  bool _hasPremiumLibrary = false;
  AppTab _selectedTab = AppTab.feed;
  ProfileForm? _profile;
  final List<SavedContent> _savedItems = [];
  int _messageStateVersion = 0;
  int _notificationStateVersion = 0;
  int _feedVersion = 0;
  int _reelsVersion = 0;
  int _storiesVersion = 0;

  bool get isBootstrapped => _isBootstrapped;

  bool get isSignedIn => _isSignedIn;

  /// User's theme preference. [AppThemeMode.system] follows the OS.
  AppThemeMode get themeMode => _themeMode;

  /// Convenience for "is the user explicitly using dark right now?"
  /// — does not reflect system dark mode. Use [themeMode] + the platform
  /// brightness if you need the *effective* color scheme.
  bool get isDarkMode => _themeMode == AppThemeMode.dark;

  bool get hasPremiumLibrary => _hasPremiumLibrary;

  AppTab get selectedTab => _selectedTab;

  ProfileForm? get profile => _profile;

  List<SavedContent> get savedItems => List.unmodifiable(_savedItems);

  int get messageStateVersion => _messageStateVersion;

  int get notificationStateVersion => _notificationStateVersion;

  /// Bumped whenever the home feed should be re-fetched (post published,
  /// post deleted, etc.). Screens cache the previous version in their State
  /// and refresh when it changes.
  int get feedVersion => _feedVersion;
  int get reelsVersion => _reelsVersion;
  int get storiesVersion => _storiesVersion;

  bool isSaved(String id) {
    return _savedItems.any((item) => item.id == id);
  }

  Future<void> bootstrap() async {
    final (signedIn, themeMode) = await (
      _sessionStore.isSignedIn(),
      _sessionStore.getThemeMode(),
    ).wait;
    _isSignedIn = signedIn;
    _themeMode = themeMode;
    themeModeListenable.value = themeMode;
    if (signedIn) {
      final (remoteProfile, remoteSavedItems, hasPremium) = await (
        repositories.profiles.currentProfile(),
        repositories.savedContent.fetch(),
        repositories.subscriptions.hasActiveSubscription(),
      ).wait;
      _profile = remoteProfile ?? _profile;
      _hasPremiumLibrary = hasPremium || (remoteProfile?.isPremium ?? false);
      _mergeSavedItems(remoteSavedItems);
    }
    _isBootstrapped = true;
    notifyListeners();
  }

  Future<void> signIn() async {
    _isSignedIn = true;
    await _sessionStore.saveSignedIn();
    await refreshSessionData();
    notifyListeners();
  }

  Future<void> signInWithPassword({
    required String login,
    required String password,
  }) async {
    await repositories.auth.signInWithPassword(
      login: login,
      password: password,
    );
    _isSignedIn = true;
    await refreshSessionData();
    notifyListeners();
  }

  Future<void> completeSignUp(
    ProfileForm profile, {
    AccountType accountType = AccountType.engineer,
    String specialization = 'مدني',
    String phone = '',
    String password = '',
  }) async {
    await repositories.auth.completeSignUp(
      profile: profile,
      accountType: accountType,
      specialization: specialization,
      phone: phone,
      password: password,
    );
    final remoteProfile = await repositories.profiles.currentProfile(
      forceRefresh: true,
    );
    _profile = remoteProfile == null
        ? profile
        : remoteProfile.copyWith(
            about: remoteProfile.about.isEmpty ? profile.about : null,
            skills: remoteProfile.skills.isEmpty ? profile.skills : null,
          );
    _isSignedIn = true;
    await _sessionStore.saveSignedIn();
    notifyListeners();
  }

  Future<void> refreshSessionData() async {
    if (!_isSignedIn) {
      return;
    }
    final (remoteProfile, remoteSavedItems, hasPremium) = await (
      repositories.profiles.currentProfile(forceRefresh: true),
      repositories.savedContent.fetch(forceRefresh: true),
      repositories.subscriptions.hasActiveSubscription(),
    ).wait;
    _profile = remoteProfile ?? _profile;
    _hasPremiumLibrary = hasPremium || (_profile?.isPremium ?? false);
    _mergeSavedItems(remoteSavedItems);
    notifyListeners();
  }

  Future<void> updateMyAbout(String about) async {
    final current = _profile;
    if (current == null) {
      return;
    }
    _profile = current.copyWith(about: about.trim());
    notifyListeners();
    await repositories.profiles.updateCurrentProfile(about: about.trim());
  }

  Future<void> updateMyAvatar(String avatarUrl) async {
    final current = _profile;
    if (current == null) {
      return;
    }
    _profile = current.copyWith(avatarUrl: avatarUrl);
    notifyListeners();
    await repositories.profiles.updateCurrentProfile(avatarUrl: avatarUrl);
  }

  Future<void> updateMyCover(String coverUrl) async {
    final current = _profile;
    if (current == null) {
      return;
    }
    _profile = current.copyWith(coverUrl: coverUrl);
    notifyListeners();
    await repositories.profiles.updateCurrentProfile(coverUrl: coverUrl);
  }

  Future<void> signOut() async {
    await repositories.auth.signOut();
    _isSignedIn = false;
    _hasPremiumLibrary = false;
    _profile = null;
    _selectedTab = AppTab.feed;
    _savedItems.clear();
    await _sessionStore.clear();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await repositories.profiles.deleteCurrentProfile();
    await repositories.auth.signOut();
    _isSignedIn = false;
    _hasPremiumLibrary = false;
    _profile = null;
    _selectedTab = AppTab.feed;
    _savedItems.clear();
    await _sessionStore.clear();
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    return setThemeMode(enabled ? AppThemeMode.dark : AppThemeMode.light);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    themeModeListenable.value = mode;
    notifyListeners();
    await _sessionStore.saveThemeMode(mode);
  }

  void selectTab(AppTab tab) {
    if (_selectedTab == tab) {
      return;
    }
    _selectedTab = tab;
    notifyListeners();
  }

  void notifyMessageStateChanged() {
    _messageStateVersion += 1;
    notifyListeners();
  }

  void notifyFeedChanged() {
    _feedVersion += 1;
    notifyListeners();
  }

  void notifyReelsChanged() {
    _reelsVersion += 1;
    notifyListeners();
  }

  void notifyStoriesChanged() {
    _storiesVersion += 1;
    notifyListeners();
  }

  void notifyNotificationStateChanged() {
    _notificationStateVersion += 1;
    notifyListeners();
  }

  Future<void> saveContent(SavedContent content) async {
    if (isSaved(content.id)) {
      return;
    }
    _savedItems.insert(0, content);
    notifyListeners();
    await repositories.savedContent.save(content);
  }

  Future<void> removeSavedContent(String id) async {
    _savedItems.removeWhere((item) => item.id == id);
    notifyListeners();
    await repositories.savedContent.remove(id);
  }

  Future<void> saveAppliedProject(SavedContent content) async {
    await removeSavedContent(content.id);
    _savedItems.insert(0, content);
    notifyListeners();
    await repositories.savedContent.save(content);
  }

  void _mergeSavedItems(List<SavedContent> remoteItems) {
    if (remoteItems.isEmpty) {
      return;
    }
    final remoteIds = remoteItems.map((item) => item.id).toSet();
    _savedItems.removeWhere((item) => remoteIds.contains(item.id));
    _savedItems.insertAll(0, remoteItems);
  }
}
