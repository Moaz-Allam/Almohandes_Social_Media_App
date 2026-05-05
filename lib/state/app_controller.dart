import 'package:flutter/foundation.dart';

import '../data/session/session_store.dart';
import '../models/app_tab.dart';
import '../models/profile_form.dart';
import '../models/saved_content.dart';

final class AppController extends ChangeNotifier {
  AppController({required SessionStore sessionStore})
    : _sessionStore = sessionStore;

  final SessionStore _sessionStore;

  bool _isBootstrapped = false;
  bool _isSignedIn = false;
  AppTab _selectedTab = AppTab.feed;
  ProfileForm? _profile;
  final List<SavedContent> _savedItems = [
    const SavedContent(
      id: 'sample:post:onboarding',
      type: SavedContentType.post,
      title: 'منشور عن تحسين تجربة التسجيل',
      subtitle: 'ريم حسن',
      detail: 'محفوظ من الصفحة الرئيسية',
    ),
    const SavedContent(
      id: 'sample:reel:workshop',
      type: SavedContentType.reel,
      title: 'ريل ورشة تصميم منتج',
      subtitle: 'ناتالي منصور',
      detail: 'محفوظ من ريلز',
    ),
    const SavedContent(
      id: 'sample:project:flutter',
      type: SavedContentType.project,
      title: 'تطبيق متابعة فرص العمل',
      subtitle: 'مشروع محفوظ · Mobile App',
      detail: 'Flutter · عن بعد · مرحلة MVP',
    ),
  ];

  bool get isBootstrapped => _isBootstrapped;

  bool get isSignedIn => _isSignedIn;

  AppTab get selectedTab => _selectedTab;

  ProfileForm? get profile => _profile;

  List<SavedContent> get savedItems => List.unmodifiable(_savedItems);

  bool isSaved(String id) {
    return _savedItems.any((item) => item.id == id);
  }

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

  void saveContent(SavedContent content) {
    if (isSaved(content.id)) {
      return;
    }
    _savedItems.insert(0, content);
    notifyListeners();
  }

  void removeSavedContent(String id) {
    _savedItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void saveAppliedProject(SavedContent content) {
    removeSavedContent(content.id);
    _savedItems.insert(0, content);
    notifyListeners();
  }
}
