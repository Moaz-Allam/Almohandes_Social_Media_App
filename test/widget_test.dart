import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tradeflow/app/linked_arabic_app.dart';
import 'package:tradeflow/core/constants/app_colors.dart';
import 'package:tradeflow/data/mappers/supabase_enum_mapper.dart';
import 'package:tradeflow/data/repositories/app_repositories.dart';
import 'package:tradeflow/data/storage/media_upload_service.dart';
import 'package:tradeflow/data/repositories/auth_repository.dart';
import 'package:tradeflow/data/repositories/comment_repository.dart';
import 'package:tradeflow/data/repositories/course_repository.dart';
import 'package:tradeflow/data/repositories/engineer_ai_repository.dart';
import 'package:tradeflow/data/repositories/feed_repository.dart';
import 'package:tradeflow/data/repositories/message_repository.dart';
import 'package:tradeflow/data/repositories/notification_repository.dart';
import 'package:tradeflow/data/repositories/profile_repository.dart';
import 'package:tradeflow/data/repositories/project_repository.dart';
import 'package:tradeflow/data/repositories/reel_repository.dart';
import 'package:tradeflow/data/repositories/saved_content_repository.dart';
import 'package:tradeflow/data/repositories/story_repository.dart';
import 'package:tradeflow/data/repositories/subscription_repository.dart';
import 'package:tradeflow/data/session/session_store.dart';
import 'package:tradeflow/models/app_theme_mode.dart';
import 'package:tradeflow/features/premium/models/premium_course.dart';
import 'package:tradeflow/models/account_type.dart';
import 'package:tradeflow/models/comment_item.dart';
import 'package:tradeflow/models/engineer_ai_message.dart';
import 'package:tradeflow/models/feed_post_model.dart';
import 'package:tradeflow/models/message_item.dart';
import 'package:tradeflow/models/network_person.dart';
import 'package:tradeflow/models/notification_item_model.dart';
import 'package:tradeflow/models/post_visibility.dart';
import 'package:tradeflow/models/profile_form.dart';
import 'package:tradeflow/models/project_application_request.dart';
import 'package:tradeflow/models/project_draft.dart';
import 'package:tradeflow/models/project_item.dart';
import 'package:tradeflow/models/reel_item.dart';
import 'package:tradeflow/models/saved_content.dart';
import 'package:tradeflow/models/story_item.dart';
import 'package:tradeflow/models/story_viewer.dart';
import 'package:tradeflow/state/app_controller.dart';
import 'package:tradeflow/state/signup_controller.dart';

void main() {
  test('account type permissions match network and project rules', () {
    expect(AccountType.engineer.canPostProjects, isTrue);
    expect(AccountType.company.canPostProjects, isTrue);
    expect(AccountType.craftsman.canPostProjects, isFalse);
    expect(AccountType.worker.canPostProjects, isFalse);
    expect(AccountType.equipment.canPostProjects, isFalse);
    expect(accountTypeFromIndustry('company'), AccountType.company);
  });

  test('signup accepts Iraqi and Egyptian phone numbers', () {
    expect(SignupController.isSupportedPhoneNumber('07712345678'), isTrue);
    expect(SignupController.isSupportedPhoneNumber('+9647712345678'), isTrue);
    expect(SignupController.isSupportedPhoneNumber('01012345678'), isTrue);
    expect(SignupController.isSupportedPhoneNumber('+201012345678'), isTrue);
    expect(SignupController.isSupportedPhoneNumber('05512345678'), isFalse);
  });

  test('governorate slug round-trips for all 18 governorates', () {
    // Edit-profile (#7) writes the slug via governorateToSupabase and reads it
    // back via governorateFromSupabase. Every governorate must round-trip.
    expect(iraqiGovernorates, hasLength(18));
    for (final arabic in iraqiGovernorates) {
      final slug = governorateToSupabase(arabic);
      expect(slug, isNotEmpty, reason: '$arabic must map to a slug');
      expect(
        governorateFromSupabase(slug),
        arabic,
        reason: '$arabic → $slug must map back to $arabic',
      );
    }
    // Unknown slugs fall back gracefully to Baghdad (signup default).
    expect(governorateToSupabase('غير معروف'), 'baghdad');
    expect(governorateFromSupabase('totally-unknown'), 'totally-unknown');
    expect(governorateFromSupabase(null), 'بغداد');
  });

  test('updateMyProfileDetails maps name, governorate, skills correctly',
      () async {
    final repo = _RecordingProfileRepository(profile: _profile());
    final controller = AppController(
      sessionStore: _MemorySessionStore(),
      repositories: _repositoriesWith(profiles: repo),
    );
    await controller.bootstrap();

    await controller.updateMyProfileDetails(
      fullName: '  أحمد  علي حسن ',
      governorate: 'البصرة',
      skills: ['حدادة', ' حدادة ', '', 'نجارة'],
      about: '  نبذة قصيرة  ',
    );

    // Repository received the storage slug + trimmed name + de-duped skills.
    expect(repo.lastFullName, 'أحمد  علي حسن'.trim());
    expect(repo.lastGovernorate, 'basra');
    expect(repo.lastSkills, ['حدادة', 'نجارة']);
    expect(repo.lastAbout, 'نبذة قصيرة');

    // In-memory profile updated optimistically (name split + Arabic location).
    final profile = controller.profile!;
    expect(profile.firstName, 'أحمد');
    expect(profile.lastName, 'علي حسن');
    expect(profile.location, 'البصرة');
    expect(profile.skills, {'حدادة', 'نجارة'});
    expect(profile.about, 'نبذة قصيرة');
  });

  testWidgets('signed-in app uses current profile and empty remote states', (
    tester,
  ) async {
    await tester.pumpWidget(
      LinkedArabicApp(
        sessionStore: _MemorySessionStore(),
        repositories: _repositories(currentProfile: _profile()),
      ),
    );
    await tester.pumpAndSettle();

    // Empty feed renders its empty-state, never a remote default profile.
    expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    expect(find.text('Remote Demo User'), findsNothing);

    // The mobile top bar greets the *current* signed-in profile by name,
    // proving the app reads currentProfile() rather than a baked-in demo user.
    expect(find.text('Current User'), findsWidgets);
  });

  testWidgets('post like toggles primary color and reaction count', (
    tester,
  ) async {
    const post = FeedPostModel(
      id: 'post-1',
      profileId: 'profile-remote',
      name: 'Remote Poster',
      headline: 'Civil engineer',
      time: 'now',
      body: 'Repository-backed post',
      reactions: '77',
      comments: '0 comments',
      avatarColor: AppColors.blue,
      showMedia: false,
    );

    await tester.pumpWidget(
      LinkedArabicApp(
        sessionStore: _MemorySessionStore(),
        repositories: _repositories(
          currentProfile: _profile(),
          posts: const [post],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Unliked: outline heart + the initial reaction count.
    expect(find.text('77'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pump();

    // Liked: filled heart in the brand "like" colour + incremented count.
    final likedIcon = tester.widget<Icon>(
      find.byIcon(Icons.favorite_rounded),
    );
    expect(find.text('78'), findsOneWidget);
    expect(likedIcon.color, const Color(0xFFF43F5E));

    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pump();

    // Back to the outline heart and original count.
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.text('77'), findsOneWidget);
  });

  testWidgets('search tab queries repository people and shows results', (
    tester,
  ) async {
    await tester.pumpWidget(
      LinkedArabicApp(
        sessionStore: _MemorySessionStore(),
        repositories: _repositories(
          currentProfile: _profile(),
          people: const [
            NetworkPerson(
              id: 'network-1',
              name: 'Repository Engineer',
              title: 'Survey engineer',
              color: AppColors.blue,
              contextLine: 'Baghdad',
              actionLabel: 'Connect',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The search experience lives behind the bottom-nav "search" tab.
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    // An empty query shows the prompt, not results.
    expect(find.text('Repository Engineer'), findsNothing);
    expect(find.text('تصفح الشبكة'), findsOneWidget);

    // Typing runs searchPeople (the default filter) after the debounce.
    await tester.enterText(find.byType(TextField), 'Repo');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Repository Engineer'), findsOneWidget);
  });
}

AppRepositories _repositories({
  ProfileForm? currentProfile,
  List<FeedPostModel> posts = const [],
  List<NetworkPerson> people = const [],
  List<NetworkPerson> companies = const [],
}) {
  return AppRepositories(
    auth: _FakeAuthRepository(),
    comments: _FakeCommentRepository(),
    courses: _FakeCourseRepository(),
    engineerAi: _FakeEngineerAiRepository(),
    feed: _FakeFeedRepository(posts),
    messages: _FakeMessageRepository(),
    notifications: _FakeNotificationRepository(),
    profiles: _FakeProfileRepository(
      profile: currentProfile,
      people: people,
      companies: companies,
    ),
    projects: _FakeProjectRepository(),
    reels: _FakeReelRepository(),
    savedContent: _FakeSavedContentRepository(),
    stories: _FakeStoryRepository(),
    subscriptions: _FakeSubscriptionRepository(),
    media: MediaUploadService(),
  );
}

/// Like [_repositories] but lets a test inject a custom profile repository so
/// it can observe what the controller writes.
AppRepositories _repositoriesWith({required ProfileRepository profiles}) {
  return AppRepositories(
    auth: _FakeAuthRepository(),
    comments: _FakeCommentRepository(),
    courses: _FakeCourseRepository(),
    engineerAi: _FakeEngineerAiRepository(),
    feed: _FakeFeedRepository(const []),
    messages: _FakeMessageRepository(),
    notifications: _FakeNotificationRepository(),
    profiles: profiles,
    projects: _FakeProjectRepository(),
    reels: _FakeReelRepository(),
    savedContent: _FakeSavedContentRepository(),
    stories: _FakeStoryRepository(),
    subscriptions: _FakeSubscriptionRepository(),
    media: MediaUploadService(),
  );
}

/// Records the arguments of the most recent [updateCurrentProfile] call so the
/// #7 edit-profile flow can be asserted without a live backend.
final class _RecordingProfileRepository extends _FakeProfileRepository {
  _RecordingProfileRepository({super.profile})
    : super(people: const [], companies: const []);

  String? lastAbout;
  String? lastFullName;
  String? lastGovernorate;
  List<String>? lastSkills;

  @override
  Future<void> updateCurrentProfile({
    String? about,
    String? avatarUrl,
    String? coverUrl,
    String? fullName,
    String? governorate,
    List<String>? skills,
  }) async {
    lastAbout = about;
    lastFullName = fullName;
    lastGovernorate = governorate;
    lastSkills = skills;
  }
}

ProfileForm _profile({
  String firstName = 'Current',
  String lastName = 'User',
  AccountType type = AccountType.engineer,
}) {
  return ProfileForm(
    id: 'profile-current',
    email: 'current@example.com',
    firstName: firstName,
    lastName: lastName,
    headline: '${type.label} - Baghdad',
    location: 'Baghdad',
    industry: type.label,
    company: type == AccountType.company ? '$firstName $lastName' : '',
    role: 'Civil',
    about: 'Current Supabase-backed user',
    skills: const {'Civil'},
    languages: const {},
    openToWork: type != AccountType.company,
    profilePublic: true,
    jobAlerts: false,
  );
}

final class _MemorySessionStore implements SessionStore {
  _MemorySessionStore();

  bool signedIn = true;
  AppThemeMode themeMode = AppThemeMode.system;
  bool profilePrivate = false;

  @override
  Future<void> clear() async => signedIn = false;

  @override
  Future<bool> isDarkMode() async => themeMode == AppThemeMode.dark;

  @override
  Future<AppThemeMode> getThemeMode() async => themeMode;

  @override
  Future<bool> isSignedIn() async => signedIn;

  @override
  Future<void> saveDarkMode(bool enabled) async =>
      themeMode = enabled ? AppThemeMode.dark : AppThemeMode.light;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async => themeMode = mode;

  @override
  Future<void> saveSignedIn() async => signedIn = true;

  @override
  Future<bool> isProfilePrivate() async => profilePrivate;

  @override
  Future<void> saveProfilePrivate(bool isPrivate) async =>
      profilePrivate = isPrivate;
}

final class _FakeAuthRepository implements AuthRepository {
  @override
  bool get isRemoteConfigured => false;

  @override
  Future<bool> phoneExists(String phone) async => false;

  @override
  Future<void> signInWithPassword({
    required String phone,
    required String password,
  }) async {}

  @override
  Future<void> sendSignupOtp({required String phone}) async {}

  @override
  Future<void> resendSignupOtp({required String phone}) async {}

  @override
  Future<void> verifySignupOtp({
    required String phone,
    required String code,
  }) async {}

  @override
  Future<void> setPasswordForCurrentUser({required String password}) async {}

  @override
  Future<void> setFullNameForCurrentUser({required String fullName}) async {}

  @override
  Future<void> completeSignUp({
    required ProfileForm profile,
    required AccountType accountType,
    required String specialization,
    required String phone,
  }) async {}

  @override
  Future<void> signOut() async {}
}

final class _FakeCourseRepository implements CourseRepository {
  @override
  Future<List<PremiumCourse>> fetchPremiumCourses({
    bool forceRefresh = false,
  }) async {
    return const [];
  }
}

final class _FakeEngineerAiRepository implements EngineerAiRepository {
  @override
  Future<List<EngineerAiMessage>> fetchMessages({
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<EngineerAiMessage> sendMessage(String content) async {
    return EngineerAiMessage(
      id: 'ai-1',
      role: EngineerAiRole.assistant,
      content: 'تم',
      createdAt: DateTime(2026),
    );
  }
}

final class _FakeCommentRepository implements CommentRepository {
  @override
  Future<CommentItem?> addComment({
    required String targetType,
    required String targetId,
    required String content,
    String? parentId,
  }) async {
    return null;
  }

  @override
  Future<List<CommentItem>> fetchComments({
    required String targetType,
    required String targetId,
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<void> toggleCommentLike({
    required String commentId,
    required bool shouldLike,
  }) async {}

  @override
  Future<({String targetType, String targetId})?> resolveCommentTarget(
    String commentId,
  ) async {
    return null;
  }
}

final class _FakeFeedRepository implements FeedRepository {
  _FakeFeedRepository(this.posts);

  final List<FeedPostModel> posts;

  @override
  Future<void> createPost({
    required String content,
    String mediaUrl = '',
    String mediaType = 'text',
    PostVisibility visibility = PostVisibility.public,
  }) async {}

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<void> repost(String postId) async {}

  @override
  Future<List<FeedPostModel>> fetchHomeFeed({
    bool forceRefresh = false,
    int offset = 0,
  }) async {
    return offset > 0 ? const [] : posts;
  }

  @override
  Future<FeedPostModel?> fetchPostById(String postId) async {
    for (final post in posts) {
      if (post.id == postId) {
        return post;
      }
    }
    return null;
  }

  @override
  Future<List<FeedPostModel>> fetchFollowingFeed({
    bool forceRefresh = false,
    int offset = 0,
  }) async {
    return offset > 0 ? const [] : posts;
  }

  @override
  Future<List<FeedPostModel>> fetchProfessionalsFeed({
    bool forceRefresh = false,
    int offset = 0,
  }) async {
    return offset > 0 ? const [] : posts;
  }

  @override
  Future<List<FeedPostModel>> fetchProfilePosts(
    String profileId, {
    bool forceRefresh = false,
  }) async {
    return posts.where((post) => post.profileId == profileId).toList();
  }

  @override
  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {}

  @override
  Future<void> toggleLike({
    required String postId,
    required bool shouldLike,
  }) async {}

  @override
  Future<List<FeedPostModel>> searchPosts(String query) async => posts;
}

final class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository({
    this.profile,
    required this.people,
    required this.companies,
  });

  final ProfileForm? profile;
  final List<NetworkPerson> people;
  final List<NetworkPerson> companies;

  @override
  Future<void> answerConnectionRequest({
    required String requestId,
    required bool accept,
  }) async {}

  @override
  Future<ProfileForm?> currentProfile({bool forceRefresh = false}) async {
    return profile;
  }

  @override
  Future<void> setProfilePrivacy(bool isPrivate) async {}

  @override
  Future<bool> isProfilePrivate(String profileId) async => false;

  @override
  Future<void> deleteCurrentProfile() async {}

  @override
  Future<void> updateCurrentProfile({
    String? about,
    String? avatarUrl,
    String? coverUrl,
    String? fullName,
    String? governorate,
    List<String>? skills,
  }) async {}

  @override
  Future<List<NetworkPerson>> fetchIncomingConnectionRequests({
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<List<NetworkPerson>> fetchMyFollowers({
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<List<NetworkPerson>> fetchMyFollowing({
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<List<NetworkPerson>> fetchMyConnections({
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<List<NetworkPerson>> fetchNetworkProfiles({
    required AccountType viewerType,
    required bool companies,
    bool forceRefresh = false,
  }) async {
    if (viewerType == AccountType.engineer) {
      return companies ? this.companies : people;
    }
    if (viewerType == AccountType.company) {
      return companies ? const [] : people;
    }
    return const [];
  }

  @override
  Future<String> connectionStatus(String otherProfileId) async => 'none';

  @override
  Future<bool> isFollowingProfile(String followingProfileId) async => false;

  @override
  Future<void> followProfile(String followingProfileId) async {}

  @override
  Future<void> unfollowProfile(String followingProfileId) async {}

  @override
  Future<void> requestConnection(String receiverProfileId) async {}

  @override
  Future<ProfileStats> fetchProfileStats(String profileId) async {
    return ProfileStats.empty;
  }

  @override
  Future<List<NetworkPerson>> searchPeople(String query) async => people;
}

final class _FakeProjectRepository implements ProjectRepository {
  @override
  Future<void> applyToProject({
    required ProjectItem project,
    required String subject,
    required String message,
    required int attachmentsCount,
  }) async {}

  @override
  Future<ProjectItem?> createProject(ProjectDraftData draft) async => null;

  @override
  Future<List<ProjectItem>> fetchProjects({bool forceRefresh = false}) async {
    return const [];
  }

  @override
  Future<List<ProjectItem>> fetchProjectsForProfile(
    String profileId, {
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<List<ProjectApplicationRequest>> fetchProjectApplications(
    String projectId, {
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<Set<String>> fetchAppliedProjectIds({
    bool forceRefresh = false,
  }) async {
    return const <String>{};
  }

  @override
  Future<List<ProjectItem>> searchJobs(String query) async => const [];
}

final class _FakeMessageRepository implements MessageRepository {
  @override
  Future<List<MessageItem>> fetchConversations({
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<List<ChatMessage>> fetchMessages(
    String conversationId, {
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {}

  @override
  Future<void> sendVoiceMessage({
    required String conversationId,
    required String voiceUrl,
  }) async {}

  @override
  Future<void> sendFileMessage({
    required String conversationId,
    required String fileName,
    required String fileUrl,
  }) async {}

  @override
  Future<void> markConversationRead(String conversationId) async {}

  @override
  Future<void> blockConnection(String profileId) async {}

  @override
  Future<void> removeConnection(String profileId) async {}

  @override
  Future<void> deleteConversation(String conversationId) async {}
}

final class _FakeNotificationRepository implements NotificationRepository {
  @override
  Future<void> delete(String notificationId) async {}

  @override
  Future<List<NotificationItemModel>> fetchNotifications({
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<void> markRead(String notificationId) async {}

  @override
  Future<void> markAllRead() async {}
}

final class _FakeReelRepository implements ReelRepository {
  @override
  Future<void> createReel({
    required String caption,
    required String videoUrl,
  }) async {}

  @override
  Future<void> deleteReel(String reelId) async {}

  @override
  Future<List<ReelItem>> fetchReels({bool forceRefresh = false}) async {
    return const [];
  }

  @override
  Future<List<ReelItem>> fetchReelsForProfile(
    String profileId, {
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<void> repost(String reelId) async {}

  @override
  Future<void> toggleLike({
    required String reelId,
    required bool shouldLike,
  }) async {}
}

final class _FakeSavedContentRepository implements SavedContentRepository {
  @override
  Future<List<SavedContent>> fetch({bool forceRefresh = false}) async {
    return const [];
  }

  @override
  Future<void> remove(String id) async {}

  @override
  Future<void> save(SavedContent content) async {}
}

final class _FakeStoryRepository implements StoryRepository {
  @override
  Future<void> createStory({
    required String content,
    String mediaUrl = '',
    String mediaType = 'text',
  }) async {}

  @override
  Future<void> createTextStory(String content) async {}

  @override
  Future<List<StoryItem>> fetchStories({bool forceRefresh = false}) async {
    return const [];
  }

  @override
  Future<void> reactToStory({
    required String storyId,
    required String emoji,
  }) async {}

  @override
  Future<void> markStoryViewed(String storyId) async {}

  @override
  Future<List<StoryViewer>> fetchStoryViewers(String storyId) async =>
      const [];
}

final class _FakeSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<PremiumCheckout> createPremiumCheckout({num amount = 120000}) async {
    return PremiumCheckout(
      checkoutId: 'test-checkout',
      paymentUrl: Uri.parse('https://example.com/pay'),
      paymentWidgetUrl: Uri.parse('https://example.com/widget.js'),
      paymentResultUrl: Uri.parse('https://example.com/result'),
      profileId: 'profile-current',
    );
  }

  @override
  Future<bool> hasActiveSubscription() async => false;

  @override
  Future<void> verifyPremiumCheckout(PremiumCheckout checkout) async {}
}
