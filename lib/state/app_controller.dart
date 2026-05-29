import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/notifications/local_notification_service.dart';
import '../data/notifications/push_token_service.dart';
import '../data/mappers/supabase_enum_mapper.dart';
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
  bool _isProfilePrivate = false;
  AppTab _selectedTab = AppTab.feed;
  ProfileForm? _profile;
  final List<SavedContent> _savedItems = [];
  int _messageStateVersion = 0;
  int _notificationStateVersion = 0;
  // Bumped ONLY by realtime pushes from the server (a row changed remotely),
  // never by the user's own actions. Message/chat/notification screens watch
  // these to refetch live, without re-firing on their own self-refreshes.
  int _realtimeMessageVersion = 0;
  int _realtimeMessageRowVersion = 0;
  Map<String, dynamic>? _latestMessageRow;
  int _realtimeNotificationVersion = 0;
  int _feedVersion = 0;
  int _reelsVersion = 0;
  int _storiesVersion = 0;
  int _followVersion = 0;

  bool get isBootstrapped => _isBootstrapped;

  bool get isSignedIn => _isSignedIn;

  /// User's theme preference. [AppThemeMode.system] follows the OS.
  AppThemeMode get themeMode => _themeMode;

  /// Convenience for "is the user explicitly using dark right now?"
  /// — does not reflect system dark mode. Use [themeMode] + the platform
  /// brightness if you need the *effective* color scheme.
  bool get isDarkMode => _themeMode == AppThemeMode.dark;

  bool get hasPremiumLibrary => _hasPremiumLibrary;

  /// True when the signed-in user's account type is "engineer". The premium
  /// dashboard ("مركز المهندس") is gated on this: only engineers may open it,
  /// every other account type (شركة/مقاول، حرفي، عامل، آليات، إدارة) is denied.
  ///
  /// [ProfileForm.role] stores the Arabic account label (e.g. "مهندس") because
  /// `currentProfile` maps the Supabase role through `AccountType.label`. We
  /// also accept the raw "engineer" slug defensively. Returns false until the
  /// profile is loaded so access never defaults open.
  bool get isEngineer {
    final profile = _profile;
    if (profile == null) {
      return false;
    }
    final role = profile.role.trim();
    return role == AccountType.engineer.label || role.toLowerCase() == 'engineer';
  }

  /// True when the current user has flipped their profile to private. A
  /// private profile is fully visible to the owner and to accepted
  /// connections, but only shows basic info to anyone else.
  bool get isProfilePrivate => _isProfilePrivate;

  AppTab get selectedTab => _selectedTab;

  ProfileForm? get profile => _profile;

  List<SavedContent> get savedItems => List.unmodifiable(_savedItems);

  int get messageStateVersion => _messageStateVersion;

  int get notificationStateVersion => _notificationStateVersion;

  /// Bumped when the server pushes a message/conversation change over realtime.
  /// Screens watch this to refetch live; it never fires for the viewer's own
  /// sends, avoiding refetch loops.
  int get realtimeMessageVersion => _realtimeMessageVersion;

  /// Bumped for each individual `messages` row pushed over realtime, paired
  /// with [latestMessageRow]. An open chat watches this to append the single
  /// new row to the right conversation instead of refetching the whole thread.
  int get realtimeMessageRowVersion => _realtimeMessageRowVersion;

  /// The most recent realtime `messages` row (raw columns), or null before any
  /// arrives. Read alongside [realtimeMessageRowVersion].
  Map<String, dynamic>? get latestMessageRow => _latestMessageRow;

  /// Bumped when the server pushes a notification change over realtime.
  int get realtimeNotificationVersion => _realtimeNotificationVersion;

  /// Bumped whenever the home feed should be re-fetched (post published,
  /// post deleted, etc.). Screens cache the previous version in their State
  /// and refresh when it changes.
  int get feedVersion => _feedVersion;
  int get reelsVersion => _reelsVersion;
  int get storiesVersion => _storiesVersion;

  /// Bumped each time the viewer follows or unfollows another profile.
  /// Screens that depend on "who I follow" (home Following feed, profile
  /// "Following" tab) watch this and refetch when it changes.
  int get followVersion => _followVersion;

  bool isSaved(String id) {
    return _savedItems.any((item) => item.id == id);
  }

  Future<void> bootstrap() async {
    final (signedIn, themeMode, profilePrivate) = await (
      _sessionStore.isSignedIn(),
      _sessionStore.getThemeMode(),
      _sessionStore.isProfilePrivate(),
    ).wait;
    _isSignedIn = signedIn;
    _themeMode = themeMode;
    _isProfilePrivate = profilePrivate;
    themeModeListenable.value = themeMode;
    if (signedIn) {
      final (remoteProfile, remoteSavedItems, hasPremium) = await (
        repositories.profiles.currentProfile(),
        repositories.savedContent.fetch(),
        repositories.subscriptions.hasActiveSubscription(),
      ).wait;
      _profile = remoteProfile ?? _profile;
      _hasPremiumLibrary = hasPremium || (remoteProfile?.isPremium ?? false);
      if (remoteProfile != null) {
        _isProfilePrivate = !remoteProfile.profilePublic;
      }
      _mergeSavedItems(remoteSavedItems);
      _startRealtime();
    }
    _isBootstrapped = true;
    notifyListeners();
  }

  Future<void> signIn() async {
    _isSignedIn = true;
    await _sessionStore.saveSignedIn();
    await refreshSessionData();
    _startRealtime();
    notifyListeners();
  }

  Future<void> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    await repositories.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
    _isSignedIn = true;
    await refreshSessionData();
    _startRealtime();
    notifyListeners();
  }

  Future<void> completeSignUp(
    ProfileForm profile, {
    AccountType accountType = AccountType.engineer,
    String specialization = 'مدني',
    String phone = '',
  }) async {
    await repositories.auth.completeSignUp(
      profile: profile,
      accountType: accountType,
      specialization: specialization,
      phone: phone,
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
    _startRealtime();
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

  /// Saves the editable profile fields (name, governorate, skills, bio) in a
  /// single round-trip. Optimistically updates the in-memory profile so the
  /// UI reflects the change immediately; the repository persists the rest.
  ///
  /// [fullName] is split into first/last names locally; [governorate] is the
  /// Arabic display value (converted to the storage slug before writing);
  /// [skills] replaces the stored set.
  Future<void> updateMyProfileDetails({
    String? fullName,
    String? governorate,
    List<String>? skills,
    String? about,
  }) async {
    final current = _profile;
    if (current == null) {
      return;
    }

    final trimmedName = fullName?.trim();
    final hasName = trimmedName != null && trimmedName.isNotEmpty;
    String? firstName;
    String? lastName;
    if (hasName) {
      final parts = trimmedName
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      firstName = parts.isEmpty ? '' : parts.first;
      lastName = parts.length <= 1 ? '' : parts.skip(1).join(' ');
    }

    final trimmedGovernorate = governorate?.trim();
    final hasGovernorate =
        trimmedGovernorate != null && trimmedGovernorate.isNotEmpty;
    final newLocation = hasGovernorate ? trimmedGovernorate : current.location;

    final cleanedSkills = skills
        ?.map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet();

    final trimmedAbout = about?.trim();

    _profile = current.copyWith(
      firstName: firstName,
      lastName: lastName,
      location: hasGovernorate ? newLocation : null,
      headline: hasGovernorate ? '${current.role} · $newLocation' : null,
      skills: cleanedSkills,
      about: trimmedAbout,
    );
    notifyListeners();

    await repositories.profiles.updateCurrentProfile(
      fullName: hasName ? trimmedName : null,
      governorate:
          hasGovernorate ? governorateToSupabase(trimmedGovernorate) : null,
      skills: cleanedSkills?.toList(),
      about: trimmedAbout,
    );
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
    _stopRealtime();
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
    _stopRealtime();
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

  Future<void> setProfilePrivate(bool isPrivate) async {
    if (_isProfilePrivate == isPrivate) {
      return;
    }
    _isProfilePrivate = isPrivate;
    notifyListeners();
    await _sessionStore.saveProfilePrivate(isPrivate);
    // Persist to the backend so RLS can hide this profile's posts from
    // non-connections.
    await repositories.profiles.setProfilePrivacy(isPrivate);
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

  void notifyFollowChanged() {
    _followVersion += 1;
    notifyListeners();
  }

  void notifyNotificationStateChanged() {
    _notificationStateVersion += 1;
    notifyListeners();
  }

  /// Called by [RealtimeService] when a message/conversation row changes
  /// remotely. Bumps the badge counter (so the unread pill updates) AND the
  /// realtime counter (so open message/chat screens refetch live).
  void notifyRealtimeMessage() {
    _messageStateVersion += 1;
    _realtimeMessageVersion += 1;
    notifyListeners();
  }

  /// Called by [RealtimeService] for each individual inserted message row.
  /// Stores the row and bumps the per-row counter so an open chat can append
  /// just this message to its conversation without a full refetch.
  void notifyRealtimeMessageRow(Map<String, dynamic> row) {
    _latestMessageRow = row;
    _realtimeMessageRowVersion += 1;
    notifyListeners();
  }

  /// Called by [RealtimeService] when a notification row changes remotely.
  /// [latest] is the changed row (title/message/is_read) when available, so we
  /// can pop a local notification without a second fetch.
  void notifyRealtimeNotification([Map<String, dynamic>? latest]) {
    _notificationStateVersion += 1;
    _realtimeNotificationVersion += 1;
    notifyListeners();
    _popLocalNotification(latest);
  }

  /// Shows the newest unread notification as a foreground OS notification.
  /// Best-effort and silent on failure / web. When the realtime payload is
  /// supplied we build the notification straight from it; only when it's
  /// missing (defensive path) do we fall back to a fetch.
  Future<void> _popLocalNotification(Map<String, dynamic>? latest) async {
    try {
      String title;
      String body;
      if (latest != null) {
        // An UPDATE that flips is_read (e.g. read on another device) is not a
        // new alert — skip it.
        if (latest['is_read'] == true) {
          return;
        }
        title = '${latest['title'] ?? ''}';
        body = '${latest['message'] ?? ''}';
        if (title.isEmpty && body.isEmpty) {
          return;
        }
      } else {
        final items = await repositories.notifications.fetchNotifications(
          forceRefresh: true,
        );
        if (items.isEmpty || !items.first.unread) {
          return;
        }
        title = items.first.title;
        body = items.first.preview;
      }
      await LocalNotificationService.instance.show(title: title, body: body);
    } catch (_) {
      // Local notification is a nicety; never surface failures.
    }
  }

  void _startRealtime() {
    final realtime = repositories.realtime;
    if (realtime == null) {
      // Tests / unconfigured envs: skip realtime + push entirely.
      return;
    }
    realtime.start(
      onMessagesChanged: notifyRealtimeMessage,
      onMessageRow: notifyRealtimeMessageRow,
      onNotificationsChanged: notifyRealtimeNotification,
    );
    // Register this device for background push (FCM / Web Push).
    unawaited(PushTokenService.register());
  }

  void _stopRealtime() {
    final realtime = repositories.realtime;
    if (realtime == null) {
      return;
    }
    realtime.stop();
    unawaited(PushTokenService.unregister());
  }

  @override
  void dispose() {
    _stopRealtime();
    super.dispose();
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
