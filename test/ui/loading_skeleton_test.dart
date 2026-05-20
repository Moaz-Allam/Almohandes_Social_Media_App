import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradeflow/core/constants/app_colors.dart';
import 'package:tradeflow/core/theme/app_theme.dart';
import 'package:tradeflow/data/repositories/app_repositories.dart';
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
import 'package:tradeflow/data/storage/media_upload_service.dart';
import 'package:tradeflow/models/app_theme_mode.dart';
import 'package:tradeflow/data/session/session_store.dart';
import 'package:tradeflow/features/feed/home_feed_screen.dart';
import 'package:tradeflow/features/premium/models/premium_course.dart';
import 'package:tradeflow/features/projects/projects_screen.dart';
import 'package:tradeflow/features/reels/reels_screen.dart';
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
import 'package:tradeflow/shared/widgets/skeleton.dart';
import 'package:tradeflow/state/app_controller.dart';
import 'package:tradeflow/state/app_scope.dart';

void main() {
  testWidgets('home feed shows skeletons while posts are loading', (
    tester,
  ) async {
    final feed = _ControlledFeedRepository();
    final controller = _controller(feed: feed);

    await tester.pumpWidget(
      _Harness(
        controller: controller,
        child: HomeFeedScreen(onMenu: () {}, onMessages: () {}),
      ),
    );
    await tester.pump();

    expect(find.byType(FeedPostSkeleton), findsAtLeastNWidgets(1));

    feed.complete(_testPosts.take(1).toList());
    await tester.pumpAndSettle();

    expect(find.byType(FeedPostSkeleton), findsNothing);
    expect(
      find.text(_testPosts.first.name, findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('projects page shows skeleton cards while projects are loading', (
    tester,
  ) async {
    final projects = _ControlledProjectRepository();
    final controller = _controller(projects: projects);

    await tester.pumpWidget(
      _Harness(
        controller: controller,
        child: ProjectsScreen(onMenu: () {}, onMessages: () {}),
      ),
    );
    await tester.pump();

    expect(find.byType(ProjectCardSkeleton), findsNWidgets(3));

    projects.complete(_testProjects.take(1).toList());
    await tester.pumpAndSettle();

    expect(find.byType(ProjectCardSkeleton), findsNothing);
    expect(find.text(_testProjects.first.title), findsOneWidget);
  });

  testWidgets('reels screen shows a circular loader before reels are loaded', (
    tester,
  ) async {
    final reels = _ControlledReelRepository();
    final controller = _controller(reels: reels);

    await tester.pumpWidget(
      _Harness(
        controller: controller,
        child: ReelsScreen(onMenu: () {}, onMessages: () {}),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    reels.complete(_testReels);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(_testReels.first.name), findsOneWidget);
  });
}

AppController _controller({
  FeedRepository? feed,
  ProjectRepository? projects,
  ReelRepository? reels,
}) {
  return AppController(
    sessionStore: _MemorySessionStore(),
    repositories: AppRepositories(
      auth: _FakeAuthRepository(),
      comments: _FakeCommentRepository(),
      courses: _FakeCourseRepository(),
      engineerAi: _FakeEngineerAiRepository(),
      feed: feed ?? _ImmediateFeedRepository(),
      messages: _FakeMessageRepository(),
      notifications: _FakeNotificationRepository(),
      profiles: _FakeProfileRepository(),
      projects: projects ?? _ImmediateProjectRepository(),
      reels: reels ?? _ImmediateReelRepository(),
      savedContent: _FakeSavedContentRepository(),
      stories: _FakeStoryRepository(),
      subscriptions: _FakeSubscriptionRepository(),
      media: MediaUploadService(),
    ),
  );
}

class _Harness extends StatelessWidget {
  const _Harness({required this.child, required this.controller});

  final Widget child;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: MaterialApp(
          locale: const Locale('ar'),
          theme: AppTheme.light,
          home: Scaffold(body: child),
        ),
      ),
    );
  }
}

final _testPosts = <FeedPostModel>[
  const FeedPostModel(
    id: 'post-1',
    profileId: 'profile-1',
    name: 'Test Engineer',
    headline: 'Civil engineer',
    time: 'now',
    body: 'A remote post loaded from the repository.',
    reactions: '12',
    comments: '3 comments',
    avatarColor: AppColors.blue,
    showMedia: false,
  ),
];

final _testProjects = <ProjectItem>[
  const ProjectItem(
    id: 'project-1',
    title: 'Remote bridge inspection',
    tagline: 'Coordinate engineering reviewers',
    category: 'Civil',
    type: 'Collaboration',
    workMode: 'Remote',
    location: 'Baghdad',
    stage: 'MVP',
    skills: ['Civil', 'QA'],
    commitment: '10h/week',
    budget: 'IQD 500K',
    postedBy: 'Test Company',
    color: AppColors.blue,
  ),
];

final _testReels = <ReelItem>[
  const ReelItem(
    id: 'reel-1',
    profileId: 'profile-1',
    name: 'Reel Engineer',
    headline: 'Project update',
    caption: 'Site progress update',
    likesCount: 18,
    commentsCount: 2,
    repostsCount: 1,
    color: AppColors.blue,
  ),
];

final class _MemorySessionStore implements SessionStore {
  bool _signedIn = true;
  AppThemeMode _themeMode = AppThemeMode.system;

  @override
  Future<void> clear() async => _signedIn = false;

  @override
  Future<bool> isDarkMode() async => _themeMode == AppThemeMode.dark;

  @override
  Future<AppThemeMode> getThemeMode() async => _themeMode;

  @override
  Future<bool> isSignedIn() async => _signedIn;

  @override
  Future<void> saveDarkMode(bool enabled) async =>
      _themeMode = enabled ? AppThemeMode.dark : AppThemeMode.light;

  @override
  Future<void> saveThemeMode(AppThemeMode mode) async => _themeMode = mode;

  @override
  Future<void> saveSignedIn() async => _signedIn = true;
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
    return true;
  }

  @override
  Future<void> checkExistence({String? email, String? phone}) async {}
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

final class _ControlledFeedRepository implements FeedRepository {
  final _completer = Completer<List<FeedPostModel>>();

  @override
  Future<void> createPost({
    required String content,
    String mediaUrl = '',
    String mediaType = 'text',
  }) async {}

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<void> repost(String postId) async {}

  @override
  Future<List<FeedPostModel>> fetchHomeFeed({bool forceRefresh = false}) {
    return _completer.future;
  }

  @override
  Future<List<FeedPostModel>> fetchProfilePosts(
    String profileId, {
    bool forceRefresh = false,
  }) {
    return Future.value(_testPosts);
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

  void complete(List<FeedPostModel> posts) {
    _completer.complete(posts);
  }
}

final class _ImmediateFeedRepository implements FeedRepository {
  @override
  Future<void> createPost({
    required String content,
    String mediaUrl = '',
    String mediaType = 'text',
  }) async {}

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<void> repost(String postId) async {}

  @override
  Future<List<FeedPostModel>> fetchHomeFeed({bool forceRefresh = false}) async {
    return _testPosts;
  }

  @override
  Future<List<FeedPostModel>> fetchProfilePosts(
    String profileId, {
    bool forceRefresh = false,
  }) async {
    return _testPosts;
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

final class _ControlledProjectRepository implements ProjectRepository {
  final _completer = Completer<List<ProjectItem>>();

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
  Future<List<ProjectItem>> fetchProjects({bool forceRefresh = false}) {
    return _completer.future;
  }

  @override
  Future<List<ProjectItem>> fetchProjectsForProfile(
    String profileId, {
    bool forceRefresh = false,
  }) async {
    return _testProjects;
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

  void complete(List<ProjectItem> projects) {
    _completer.complete(projects);
  }
}

final class _ImmediateProjectRepository implements ProjectRepository {
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
    return _testProjects;
  }

  @override
  Future<List<ProjectItem>> fetchProjectsForProfile(
    String profileId, {
    bool forceRefresh = false,
  }) async {
    return _testProjects;
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

final class _ControlledReelRepository implements ReelRepository {
  final _completer = Completer<List<ReelItem>>();

  @override
  Future<void> createReel({
    required String caption,
    required String videoUrl,
  }) async {}

  @override
  Future<void> deleteReel(String reelId) async {}

  @override
  Future<List<ReelItem>> fetchReels({bool forceRefresh = false}) {
    return _completer.future;
  }

  @override
  Future<List<ReelItem>> fetchReelsForProfile(
    String profileId, {
    bool forceRefresh = false,
  }) async {
    return const [];
  }

  @override
  Future<void> toggleLike({
    required String reelId,
    required bool shouldLike,
  }) async {}

  @override
  Future<void> repost(String reelId) async {}

  void complete(List<ReelItem> reels) {
    _completer.complete(reels);
  }
}

final class _ImmediateReelRepository implements ReelRepository {
  @override
  Future<void> createReel({
    required String caption,
    required String videoUrl,
  }) async {}

  @override
  Future<void> deleteReel(String reelId) async {}

  @override
  Future<List<ReelItem>> fetchReels({bool forceRefresh = false}) async {
    return _testReels;
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

final class _FakeProfileRepository implements ProfileRepository {
  @override
  Future<void> answerConnectionRequest({
    required String requestId,
    required bool accept,
  }) async {}

  @override
  Future<ProfileForm?> currentProfile({bool forceRefresh = false}) async {
    return null;
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
  Future<List<NetworkPerson>> fetchMyFollowers({
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
