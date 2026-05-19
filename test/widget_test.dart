import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tradeflow/app/linked_arabic_app.dart';
import 'package:tradeflow/core/constants/app_colors.dart';
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
import 'package:tradeflow/features/home/widgets/linked_bottom_navigation.dart';
import 'package:tradeflow/features/premium/models/premium_course.dart';
import 'package:tradeflow/models/account_type.dart';
import 'package:tradeflow/models/comment_item.dart';
import 'package:tradeflow/models/engineer_ai_message.dart';
import 'package:tradeflow/models/feed_post_model.dart';
import 'package:tradeflow/models/message_item.dart';
import 'package:tradeflow/models/network_person.dart';
import 'package:tradeflow/models/notification_item_model.dart';
import 'package:tradeflow/models/profile_form.dart';
import 'package:tradeflow/models/project_application_request.dart';
import 'package:tradeflow/models/project_draft.dart';
import 'package:tradeflow/models/project_item.dart';
import 'package:tradeflow/models/reel_item.dart';
import 'package:tradeflow/models/saved_content.dart';
import 'package:tradeflow/models/story_item.dart';
import 'package:tradeflow/shared/widgets/primary_button.dart';
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

  testWidgets('registration shows success then opens the signed-in shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      LinkedArabicApp(
        sessionStore: _MemorySessionStore(signedIn: false),
        repositories: _repositories(currentProfile: _profile()),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> dismissSnacks() async {
      // AppSnack toasts auto-dismiss after a few seconds, but the SnackBar
      // timer doesn't schedule frames, so pumpAndSettle returns while the
      // snackbar is still visible (and can overlap bottom buttons).
      // Advance the clock manually past its duration.
      await tester.pump(const Duration(seconds: 6));
    }

    await tester.tap(find.byType(PrimaryButton).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Current User');
    await tester.enterText(find.byType(TextField).at(1), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(2), '07712345678');
    await tester.enterText(find.byType(TextField).at(3), 'secret123');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -460));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNWidgets(5));
    await tester.enterText(find.byType(TextField).last, 'secret123');
    await tester.tap(find.byType(PrimaryButton).last);
    await tester.pumpAndSettle();
    await dismissSnacks();

    await tester.enterText(find.byType(TextField).last, '123456');
    await tester.tap(find.byType(PrimaryButton).last);
    await tester.pumpAndSettle();
    await dismissSnacks();

    await tester.tap(find.byType(PrimaryButton).last);
    await tester.pumpAndSettle();
    await dismissSnacks();
    await tester.tap(find.byType(PrimaryButton).last);
    await tester.pumpAndSettle();
    await dismissSnacks();
    await tester.tap(find.byType(PrimaryButton).last);
    await tester.pumpAndSettle();
    await dismissSnacks();
    await tester.enterText(
      find.byType(TextField).first,
      'مهندس متخصص في المشاريع السكنية والتجارية.',
    );
    await tester.tap(find.byType(PrimaryButton).last);
    await tester.pumpAndSettle();
    await dismissSnacks();

    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump();

    expect(find.byType(LinkedBottomNavigation), findsOneWidget);
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

    expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    expect(find.text('Remote Demo User'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-menu-avatar')).first);
    await tester.pumpAndSettle();

    expect(find.text('Current User'), findsOneWidget);

    await tester.tap(find.text('Current User'));
    await tester.pumpAndSettle();

    expect(find.text('Current User'), findsWidgets);
    expect(find.text('Remote Demo User'), findsNothing);
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

    const likeKey = ValueKey('post-like-action-Remote Poster');
    final likeAction = find.byKey(likeKey);

    expect(find.text('77'), findsOneWidget);
    expect(
      find.descendant(
        of: likeAction,
        matching: find.byIcon(Icons.thumb_up_alt_outlined),
      ),
      findsOneWidget,
    );

    await tester.tap(likeAction);
    await tester.pump();

    final likedIcon = tester.widget<Icon>(
      find.descendant(
        of: likeAction,
        matching: find.byIcon(Icons.thumb_up_alt),
      ),
    );
    expect(find.text('78'), findsOneWidget);
    expect(likedIcon.color, AppColors.blue);

    await tester.tap(likeAction);
    await tester.pump();

    final unlikedIcon = tester.widget<Icon>(
      find.descendant(
        of: likeAction,
        matching: find.byIcon(Icons.thumb_up_alt_outlined),
      ),
    );
    expect(find.text('77'), findsOneWidget);
    expect(unlikedIcon.color, AppColors.muted);
  });

  testWidgets('network page loads repository people and uses right chevron', (
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

    await tester.tap(find.byIcon(Icons.people_alt));
    await tester.pumpAndSettle();

    expect(find.text('Repository Engineer'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsAtLeastNWidgets(1));
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
  _MemorySessionStore({this.signedIn = true});

  bool signedIn;
  AppThemeMode themeMode = AppThemeMode.system;

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
}

final class _FakeAuthRepository implements AuthRepository {
  @override
  bool get isRemoteConfigured => false;

  @override
  Future<void> completeSignUp({
    required ProfileForm profile,
    required AccountType accountType,
    required String specialization,
    required String phone,
    required String password,
  }) async {}

  @override
  Future<void> sendPasswordReset({required String email}) async {}

  @override
  Future<void> updatePassword({required String password}) async {}

  @override
  Future<String?> sendOtp({required String phone}) async => null;

  @override
  Future<void> signInWithPassword({
    required String login,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> verifyOtp({required String phone, required String code}) async {
    return code == '123456';
  }
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
}

final class _FakeFeedRepository implements FeedRepository {
  _FakeFeedRepository(this.posts);

  final List<FeedPostModel> posts;

  @override
  Future<void> createPost({
    required String content,
    String mediaUrl = '',
    String mediaType = 'text',
  }) async {}

  @override
  Future<void> repost(String postId) async {}

  @override
  Future<List<FeedPostModel>> fetchHomeFeed({bool forceRefresh = false}) async {
    return posts;
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
  Future<void> deleteCurrentProfile() async {}

  @override
  Future<void> updateCurrentProfile({
    String? about,
    String? avatarUrl,
    String? coverUrl,
  }) async {}

  @override
  Future<List<NetworkPerson>> fetchIncomingConnectionRequests({
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
  Future<void> requestConnection(String receiverProfileId) async {}
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
}

final class _FakeReelRepository implements ReelRepository {
  @override
  Future<void> createReel({
    required String caption,
    required String videoUrl,
  }) async {}

  @override
  Future<List<ReelItem>> fetchReels({bool forceRefresh = false}) async {
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
