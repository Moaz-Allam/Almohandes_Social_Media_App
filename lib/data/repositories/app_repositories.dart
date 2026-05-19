import '../session/session_store.dart';
import '../storage/media_upload_service.dart';
import '../supabase/supabase_bootstrap.dart';
import 'auth_repository.dart';
import 'comment_repository.dart';
import 'course_repository.dart';
import 'engineer_ai_repository.dart';
import 'feed_repository.dart';
import 'message_repository.dart';
import 'notification_repository.dart';
import 'profile_repository.dart';
import 'project_repository.dart';
import 'reel_repository.dart';
import 'saved_content_repository.dart';
import 'story_repository.dart';
import 'subscription_repository.dart';

final class AppRepositories {
  AppRepositories({
    required this.auth,
    required this.comments,
    required this.courses,
    required this.engineerAi,
    required this.feed,
    required this.messages,
    required this.notifications,
    required this.profiles,
    required this.projects,
    required this.reels,
    required this.savedContent,
    required this.stories,
    required this.subscriptions,
    required this.media,
  });

  factory AppRepositories.production({required SessionStore sessionStore}) {
    final client = SupabaseBootstrap.maybeClient();
    return AppRepositories(
      auth: SupabaseAuthRepository(client: client, sessionStore: sessionStore),
      comments: SupabaseCommentRepository(client: client),
      courses: SupabaseCourseRepository(client: client),
      engineerAi: SupabaseEngineerAiRepository(client: client),
      feed: SupabaseFeedRepository(client: client),
      messages: SupabaseMessageRepository(client: client),
      notifications: SupabaseNotificationRepository(client: client),
      profiles: SupabaseProfileRepository(client: client),
      projects: SupabaseProjectRepository(client: client),
      reels: SupabaseReelRepository(client: client),
      savedContent: SupabaseSavedContentRepository(client: client),
      stories: SupabaseStoryRepository(client: client),
      subscriptions: SupabaseSubscriptionRepository(client: client),
      media: MediaUploadService(client: client),
    );
  }

  final AuthRepository auth;
  final CommentRepository comments;
  final CourseRepository courses;
  final EngineerAiRepository engineerAi;
  final FeedRepository feed;
  final MessageRepository messages;
  final NotificationRepository notifications;
  final ProfileRepository profiles;
  final ProjectRepository projects;
  final ReelRepository reels;
  final SavedContentRepository savedContent;
  final StoryRepository stories;
  final SubscriptionRepository subscriptions;
  final MediaUploadService media;
}
