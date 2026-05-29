import 'package:supabase_flutter/supabase_flutter.dart';

import '../session/current_profile_resolver.dart';

import '../../core/constants/app_colors.dart';
import '../../models/story_item.dart';
import '../../models/story_viewer.dart';
import '../cache/timed_memory_cache.dart';
import 'repository_failure.dart';

abstract interface class StoryRepository {
  Future<List<StoryItem>> fetchStories({bool forceRefresh = false});

  Future<void> createStory({
    required String content,
    String mediaUrl = '',
    String mediaType = 'text',
  });

  Future<void> createTextStory(String content);

  /// Records the viewer's emoji reaction to a story. The server-side trigger
  /// `app_story_reactions_after_insert` notifies the creator.
  Future<void> reactToStory({
    required String storyId,
    required String emoji,
  });

  /// Records that the current viewer opened [storyId] so it persists as
  /// "seen" and bumps the story's unique view counter. Best-effort: a failure
  /// never blocks viewing.
  Future<void> markStoryViewed(String storyId);

  /// Returns the people who viewed [storyId], newest first. Row-level
  /// security only returns rows to the story's creator, so this is empty for
  /// anyone else.
  Future<List<StoryViewer>> fetchStoryViewers(String storyId);
}

final class SupabaseStoryRepository implements StoryRepository {
  SupabaseStoryRepository({required this.client});

  static const _storiesPageSize = 16;

  final SupabaseClient? client;
  final _cache = TimedMemoryCache<List<StoryItem>>(
    ttl: const Duration(seconds: 45),
  );

  @override
  Future<List<StoryItem>> fetchStories({bool forceRefresh = false}) {
    return _cache.read(_fetchStories, forceRefresh: forceRefresh);
  }

  Future<List<StoryItem>> _fetchStories() async {
    final remote = client;
    if (remote == null) {
      return const [];
    }

    try {
      List<dynamic> rows;
      try {
        rows = await remote
            .from('stories')
            .select(
              'id,profile_id,content,media_url,media_type,created_at,views_count,profiles(full_name,role,avatar_url)',
            )
            .eq('is_archived', false)
            .gt('expires_at', DateTime.now().toIso8601String())
            .order('created_at', ascending: false)
            .limit(_storiesPageSize);
      } catch (_) {
        // Older schema without views_count — fall back gracefully.
        rows = await remote
            .from('stories')
            .select(
              'id,profile_id,content,media_url,media_type,created_at,profiles(full_name,role,avatar_url)',
            )
            .eq('is_archived', false)
            .gt('expires_at', DateTime.now().toIso8601String())
            .order('created_at', ascending: false)
            .limit(_storiesPageSize);
      }
      final stories = [
        for (var i = 0; i < rows.length; i++)
          _storyFromRow(Map<String, dynamic>.from(rows[i] as Map), i),
      ];
      return _markSeen(remote, stories);
    } catch (_) {
      return const [];
    }
  }

  /// Stamps `seen` on each story by looking up the current viewer's rows in
  /// `story_views`. RLS only returns the viewer's own rows, so this never
  /// leaks other people's view history. Best-effort: any failure leaves the
  /// stories unmarked rather than hiding them.
  Future<List<StoryItem>> _markSeen(
    SupabaseClient remote,
    List<StoryItem> stories,
  ) async {
    if (stories.isEmpty) {
      return stories;
    }
    try {
      final viewerId = await _currentProfileId(remote);
      if (viewerId == null) {
        return stories;
      }
      final ids = stories.map((s) => s.id).toList();
      final rows = await remote
          .from('story_views')
          .select('story_id')
          .eq('viewer_profile_id', viewerId)
          .inFilter('story_id', ids);
      final seenIds = <String>{
        for (final row in rows) '${(row as Map)['story_id']}',
      };
      if (seenIds.isEmpty) {
        return stories;
      }
      return [
        for (final story in stories)
          seenIds.contains(story.id) ? story.copyWith(seen: true) : story,
      ];
    } catch (_) {
      return stories;
    }
  }

  @override
  Future<void> createTextStory(String content) async {
    await createStory(content: content);
  }

  @override
  Future<void> createStory({
    required String content,
    String mediaUrl = '',
    String mediaType = 'text',
  }) async {
    final remote = client;
    final trimmed = content.trim();
    if (remote == null || (trimmed.isEmpty && mediaUrl.trim().isEmpty)) {
      return;
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        throw const RepositoryFailure('سجل الدخول أولا لنشر القصة');
      }
      final payload = {
        'profile_id': profileId,
        'content': trimmed,
        'media_url': mediaUrl.trim(),
        'media_type': mediaType == 'video' ? 'video' : 'image',
        'is_archived': false,
        'expires_at': DateTime.now()
            .add(const Duration(hours: 24))
            .toIso8601String(),
      };
      try {
        await remote.from('stories').insert(payload);
      } catch (_) {
        await remote.from('stories').insert({
          'profile_id': profileId,
          'content': trimmed,
          'media_url': mediaUrl.trim(),
          'media_type': mediaType == 'video' ? 'video' : 'image',
        });
      }
      _cache.clear();
    } on RepositoryFailure {
      rethrow;
    } catch (error) {
      throw RepositoryFailure('تعذر نشر القصة الآن', error);
    }
  }

  @override
  Future<void> reactToStory({
    required String storyId,
    required String emoji,
  }) async {
    final remote = client;
    if (remote == null || storyId.isEmpty || emoji.isEmpty) {
      return;
    }
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return;
      }
      await remote.from('story_reactions').upsert({
        'story_id': storyId,
        'profile_id': profileId,
        'emoji': emoji,
      }, onConflict: 'story_id,profile_id');
    } catch (error) {
      // The story_reactions table is created by the social_visibility
      // migration. If a deployment hasn't applied it yet, fall back to
      // story_likes so the creator still receives some signal.
      try {
        final profileId = await _currentProfileId(remote);
        if (profileId == null) {
          return;
        }
        await remote.from('story_likes').upsert({
          'story_id': storyId,
          'profile_id': profileId,
        }, onConflict: 'story_id,profile_id');
      } catch (_) {
        // Reactions stay best-effort if neither table is available.
      }
    }
  }

  @override
  Future<void> markStoryViewed(String storyId) async {
    final remote = client;
    if (remote == null || storyId.isEmpty) {
      return;
    }
    try {
      final viewerId = await _currentProfileId(remote);
      if (viewerId == null) {
        return;
      }
      // SECURITY DEFINER RPC: inserts the (story, viewer) row once and bumps
      // stories.views_count only on a genuinely new view.
      await remote.rpc<void>(
        'increment_story_view',
        params: {
          'p_story_id': storyId,
          'p_viewer_profile_id': viewerId,
        },
      );
      _cache.clear();
    } catch (_) {
      // Best-effort: losing a view record must never block the viewer.
    }
  }

  @override
  Future<List<StoryViewer>> fetchStoryViewers(String storyId) async {
    final remote = client;
    if (remote == null || storyId.isEmpty) {
      return const [];
    }
    try {
      final rows = await remote
          .from('story_views')
          .select('created_at,viewer_profile_id,profiles(full_name,role,avatar_url)')
          .eq('story_id', storyId)
          .order('created_at', ascending: false);
      return [
        for (final row in rows)
          _viewerFromRow(Map<String, dynamic>.from(row as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  StoryViewer _viewerFromRow(Map<String, dynamic> row) {
    final profile = row['profiles'] is Map
        ? Map<String, dynamic>.from(row['profiles'] as Map)
        : <String, dynamic>{};
    final name = '${profile['full_name'] ?? 'مستخدم'}'.trim();
    return StoryViewer(
      profileId: '${row['viewer_profile_id'] ?? ''}',
      name: name.isEmpty ? 'مستخدم' : name,
      role: '${profile['role'] ?? ''}',
      avatarUrl: profile['avatar_url'] == null
          ? null
          : '${profile['avatar_url']}',
      viewedAt: DateTime.tryParse('${row['created_at'] ?? ''}'),
    );
  }

  StoryItem _storyFromRow(Map<String, dynamic> row, int index) {
    final profile = row['profiles'] is Map
        ? Map<String, dynamic>.from(row['profiles'] as Map)
        : <String, dynamic>{};
    final name = '${profile['full_name'] ?? 'مستخدم'}'.trim();
    return StoryItem(
      id: '${row['id']}',
      profileId: '${row['profile_id'] ?? ''}',
      name: name.isEmpty ? 'مستخدم' : name,
      content: '${row['content'] ?? ''}',
      mediaUrl: '${row['media_url'] ?? ''}',
      mediaType: '${row['media_type'] ?? 'text'}',
      avatarUrl: profile['avatar_url'] == null
          ? null
          : '${profile['avatar_url']}',
      isNew: true,
      viewsCount: switch (row['views_count']) {
        final int v => v,
        final num v => v.toInt(),
        _ => 0,
      },
      color: switch (index % 4) {
        0 => AppColors.blue,
        1 => AppColors.darkBlue,
        2 => AppColors.muted,
        _ => AppColors.black,
      },
    );
  }

  Future<String?> _currentProfileId(SupabaseClient remote) =>
      CurrentProfileResolver.instance.resolve(client: remote);
}
