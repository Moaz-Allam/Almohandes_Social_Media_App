import 'package:supabase_flutter/supabase_flutter.dart';

import '../session/current_profile_resolver.dart';

import '../../models/feed_post_model.dart';
import '../../models/post_visibility.dart';
import '../cache/timed_memory_cache.dart';
import '../mappers/feed_mapper.dart';
import '../notifications/notification_push_dispatcher.dart';
import 'repository_failure.dart';

abstract interface class FeedRepository {
  /// Fetches one page of the home feed. [offset] is the number of rows to
  /// skip (raw, server-side) so the screen can load more on scroll. Only the
  /// first page (`offset == 0`) is cached.
  Future<List<FeedPostModel>> fetchHomeFeed({
    bool forceRefresh = false,
    int offset = 0,
  });

  /// Loads a single post by id. Used for notification / deep-link
  /// navigation (`app://post/<id>`). Returns null if not found or hidden.
  Future<FeedPostModel?> fetchPostById(String postId);

  /// Server-side search across active posts by content. Returns up to a page
  /// of matches; empty when [query] is blank.
  Future<List<FeedPostModel>> searchPosts(String query);

  /// Returns home-feed posts authored by profiles the viewer follows.
  Future<List<FeedPostModel>> fetchFollowingFeed({
    bool forceRefresh = false,
    int offset = 0,
  });

  /// Returns home-feed posts authored by craftsmen and workers.
  Future<List<FeedPostModel>> fetchProfessionalsFeed({
    bool forceRefresh = false,
    int offset = 0,
  });

  Future<List<FeedPostModel>> fetchProfilePosts(
    String profileId, {
    bool forceRefresh = false,
  });

  Future<void> createPost({
    required String content,
    String mediaUrl = '',
    String mediaType = 'text',
    PostVisibility visibility = PostVisibility.public,
  });

  Future<void> deletePost(String postId);

  Future<void> toggleLike({required String postId, required bool shouldLike});

  Future<void> repost(String postId);

  Future<void> reportPost({required String postId, required String reason});
}

final class SupabaseFeedRepository implements FeedRepository {
  SupabaseFeedRepository({required this.client});

  static const _feedPageSize = 20;
  static const _profilePageSize = 24;
  static const _searchPageSize = 24;

  final SupabaseClient? client;
  final _cache = TimedMemoryCache<List<FeedPostModel>>(
    ttl: const Duration(minutes: 1),
  );
  final _followingCache = TimedMemoryCache<List<FeedPostModel>>(
    ttl: const Duration(minutes: 1),
  );
  final _professionalsCache = TimedMemoryCache<List<FeedPostModel>>(
    ttl: const Duration(minutes: 1),
  );
  // LRU cap: per-profile post caches are useful for the recently-viewed
  // profiles only. Without a cap, browsing through many profiles leaks one
  // cache (with image URL lists + decoded data) per profile id for the
  // lifetime of the app.
  static const _maxProfileCaches = 16;
  final _profileCaches = <String, TimedMemoryCache<List<FeedPostModel>>>{};

  @override
  Future<List<FeedPostModel>> fetchHomeFeed({
    bool forceRefresh = false,
    int offset = 0,
  }) async {
    // Subsequent pages bypass the cache (which holds only the first page).
    if (offset > 0) {
      return _fetchHomeFeed(offset: offset);
    }
    return _cache.read(_fetchHomeFeed, forceRefresh: forceRefresh);
  }

  Future<List<FeedPostModel>> _fetchHomeFeed({int offset = 0}) async {
    final remote = client;
    if (remote == null) {
      return const [];
    }

    // The `get_home_feed` RPC requires `p_profile_id` (no SQL default), so it
    // can only be called once we've resolved the viewer's profile. Calling it
    // with `p_limit` alone always 404s (PGRST202) and burns a round-trip, so
    // when there's no profile (signed out / not resolved yet) we skip the RPC
    // entirely and query the table directly.
    final profileId = await _currentProfileId(remote);
    if (profileId != null) {
      try {
        final rows = await remote.rpc<List<dynamic>>(
          'get_home_feed',
          params: {
            'p_profile_id': profileId,
            'p_limit': _feedPageSize,
            'p_offset': offset,
          },
        );
        return _postsFromRows(rows);
      } catch (_) {
        // RPC missing/renamed on this deployment — fall through to the table.
      }
    }

    final to = offset + _feedPageSize - 1;
    try {
      final rows = await remote
          .from('posts')
          .select(
            'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,visibility,repost_of_post_id,repost_original_profile_id,repost_original_name,profiles!posts_profile_id_fkey(full_name,role,avatar_url,governorate)',
          )
          .eq('is_active', true)
          .eq('is_archived', false)
          .order('created_at', ascending: false)
          .range(offset, to);
      return _postsFromRows(rows);
    } catch (_) {
      try {
        final rows = await remote
            .from('posts')
            .select(
              'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,profiles!posts_profile_id_fkey(full_name,role,avatar_url,governorate)',
            )
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .range(offset, to);
        return _postsFromRows(rows);
      } catch (_) {
        return const [];
      }
    }
  }

  @override
  Future<FeedPostModel?> fetchPostById(String postId) async {
    final remote = client;
    if (remote == null || postId.isEmpty) {
      return null;
    }
    const fullSelect =
        'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,visibility,'
        'repost_of_post_id,repost_original_profile_id,repost_original_name,'
        'profiles!posts_profile_id_fkey(full_name,role,avatar_url,governorate)';
    const baseSelect =
        'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,'
        'profiles!posts_profile_id_fkey(full_name,role,avatar_url,governorate)';
    const minimalSelect =
        'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at';
    for (final select in const [fullSelect, baseSelect, minimalSelect]) {
      try {
        final row = await remote
            .from('posts')
            .select(select)
            .eq('id', postId)
            .maybeSingle();
        if (row == null) {
          return null;
        }
        return feedPostFromSupabase(
          Map<String, dynamic>.from(row),
          colorIndex: 0,
        );
      } catch (_) {
        // Try the next, simpler select (a column may be missing on this
        // deployment, or RLS rejected the embedded profile join).
        continue;
      }
    }
    return null;
  }

  @override
  Future<List<FeedPostModel>> searchPosts(String query) async {
    final remote = client;
    final term = _sanitizeSearchTerm(query);
    if (remote == null || term.isEmpty) {
      return const [];
    }
    final pattern = '%$term%';
    const fullSelect =
        'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,visibility,'
        'repost_of_post_id,repost_original_profile_id,repost_original_name,'
        'profiles!posts_profile_id_fkey(full_name,role,avatar_url,governorate)';
    const minimalSelect =
        'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,'
        'profiles!posts_profile_id_fkey(full_name,role,avatar_url,governorate)';
    for (final select in const [fullSelect, minimalSelect]) {
      try {
        final rows = await remote
            .from('posts')
            .select(select)
            .ilike('content', pattern)
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .limit(_searchPageSize);
        return _postsFromRows(rows);
      } catch (_) {
        // Try the simpler select (a column may be missing on this deployment).
        continue;
      }
    }
    return const [];
  }

  /// Strips SQL `LIKE` wildcards so raw user input can't inject unintended
  /// wildcard matches into the search pattern.
  String _sanitizeSearchTerm(String query) =>
      query.replaceAll(RegExp(r'[%_]'), ' ').trim();

  @override
  Future<List<FeedPostModel>> fetchFollowingFeed({
    bool forceRefresh = false,
    int offset = 0,
  }) {
    if (offset > 0) {
      return _fetchFollowingFeed(offset: offset);
    }
    return _followingCache.read(
      _fetchFollowingFeed,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<FeedPostModel>> _fetchFollowingFeed({int offset = 0}) async {
    final remote = client;
    if (remote == null) {
      return const [];
    }
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return const [];
      }
      // 1) Followed profile IDs.
      final follows = await remote
          .from('followers')
          .select('following_id')
          .eq('follower_id', profileId);
      final followedIds = <String>{
        for (final raw in follows)
          '${(raw as Map)['following_id'] ?? ''}',
      }..removeWhere((id) => id.isEmpty);
      if (followedIds.isEmpty) {
        return const [];
      }
      // 2) Posts authored by those profiles.
      final rows = await remote
          .from('posts')
          .select(
            'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,visibility,repost_of_post_id,repost_original_profile_id,repost_original_name,profiles!posts_profile_id_fkey(full_name,role,avatar_url,governorate)',
          )
          .inFilter('profile_id', followedIds.toList())
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + _feedPageSize - 1);
      return _postsFromRows(rows);
    } catch (_) {
      // Visibility column or is_archived column may be missing — retry minimal.
      try {
        final profileId = await _currentProfileId(remote);
        if (profileId == null) {
          return const [];
        }
        final follows = await remote
            .from('followers')
            .select('following_id')
            .eq('follower_id', profileId);
        final followedIds = <String>{
          for (final raw in follows)
            '${(raw as Map)['following_id'] ?? ''}',
        }..removeWhere((id) => id.isEmpty);
        if (followedIds.isEmpty) {
          return const [];
        }
        final rows = await remote
            .from('posts')
            .select(
              'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,profiles!posts_profile_id_fkey(full_name,role,avatar_url,governorate)',
            )
            .inFilter('profile_id', followedIds.toList())
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .range(offset, offset + _feedPageSize - 1);
        return _postsFromRows(rows);
      } catch (_) {
        return const [];
      }
    }
  }

  @override
  Future<List<FeedPostModel>> fetchProfessionalsFeed({
    bool forceRefresh = false,
    int offset = 0,
  }) {
    if (offset > 0) {
      return _fetchProfessionalsFeed(offset: offset);
    }
    return _professionalsCache.read(
      _fetchProfessionalsFeed,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<FeedPostModel>> _fetchProfessionalsFeed({int offset = 0}) async {
    final remote = client;
    if (remote == null) {
      return const [];
    }
    try {
      final rows = await remote
          .from('posts')
          .select(
            'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,visibility,repost_of_post_id,repost_original_profile_id,repost_original_name,profiles!posts_profile_id_fkey!inner(full_name,role,avatar_url,governorate)',
          )
          .inFilter('profiles.role', ['craftsman', 'worker'])
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + _feedPageSize - 1);
      return _postsFromRows(rows);
    } catch (_) {
      try {
        final rows = await remote
            .from('posts')
            .select(
              'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,profiles!posts_profile_id_fkey!inner(full_name,role,avatar_url,governorate)',
            )
            .inFilter('profiles.role', ['craftsman', 'worker'])
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .range(offset, offset + _feedPageSize - 1);
        return _postsFromRows(rows);
      } catch (_) {
        return const [];
      }
    }
  }

  @override
  Future<List<FeedPostModel>> fetchProfilePosts(
    String profileId, {
    bool forceRefresh = false,
  }) {
    final existing = _profileCaches.remove(profileId);
    final cache = existing ??
        TimedMemoryCache<List<FeedPostModel>>(
          ttl: const Duration(minutes: 1),
        );
    // Reinsert (or insert) at the end so iteration order reflects recency.
    _profileCaches[profileId] = cache;
    while (_profileCaches.length > _maxProfileCaches) {
      _profileCaches.remove(_profileCaches.keys.first);
    }
    return cache.read(
      () => _fetchProfilePosts(profileId),
      forceRefresh: forceRefresh,
    );
  }

  Future<List<FeedPostModel>> _fetchProfilePosts(String profileId) async {
    final remote = client;
    if (remote == null || profileId.isEmpty) {
      return const [];
    }
    return _fetchProfilePostsRaw(remote, profileId);
  }

  Future<List<FeedPostModel>> _fetchProfilePostsRaw(
    SupabaseClient remote,
    String profileId,
  ) async {

    // Try progressively-simpler selects so a single missing/renamed column
    // (or RLS quirk) doesn't silently hide the entire profile feed.
    const fullSelect =
        'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,visibility,'
        'repost_of_post_id,repost_original_profile_id,repost_original_name,'
        'profiles!posts_profile_id_fkey(full_name,role,avatar_url,governorate)';
    const baseSelect =
        'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,'
        'profiles!posts_profile_id_fkey(full_name,role,avatar_url,governorate)';
    const minimalSelect =
        'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at';

    Future<List<FeedPostModel>> tryQuery({
      required String select,
      required bool withArchivedFilter,
    }) async {
      var query = remote
          .from('posts')
          .select(select)
          .eq('profile_id', profileId)
          .eq('is_active', true);
      if (withArchivedFilter) {
        query = query.eq('is_archived', false);
      }
      final rows = await query
          .order('created_at', ascending: false)
          .limit(_profilePageSize);
      return [
        for (var i = 0; i < rows.length; i++)
          feedPostFromSupabase(
            Map<String, dynamic>.from(rows[i] as Map),
            colorIndex: i,
          ),
      ];
    }

    // Attempt 1: full select including repost columns.
    try {
      return await tryQuery(select: fullSelect, withArchivedFilter: true);
    } catch (_) {
      // Maybe one of the repost_* columns or the is_archived column is
      // missing on this deployment. Fall through.
    }
    // Attempt 2: base select (no repost columns), still respect archive.
    try {
      return await tryQuery(select: baseSelect, withArchivedFilter: true);
    } catch (_) {
      // Fall through.
    }
    // Attempt 3: drop the is_archived filter (some older schemas don't
    // have the column at all).
    try {
      return await tryQuery(select: baseSelect, withArchivedFilter: false);
    } catch (_) {
      // Fall through.
    }
    // Attempt 4: minimal select with no joined profile.
    try {
      return await tryQuery(select: minimalSelect, withArchivedFilter: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> createPost({
    required String content,
    String mediaUrl = '',
    String mediaType = 'text',
    PostVisibility visibility = PostVisibility.public,
  }) async {
    final remote = client;
    final trimmed = content.trim();
    if (remote == null || (trimmed.isEmpty && mediaUrl.trim().isEmpty)) {
      return;
    }

    final profileId = await _currentProfileId(remote);
    if (profileId == null) {
      throw const RepositoryFailure('سجل الدخول أولا لنشر المنشور');
    }
    final basePayload = <String, dynamic>{
      'profile_id': profileId,
      'content': trimmed,
      if (mediaUrl.trim().isNotEmpty) 'image_url': mediaUrl.trim(),
      'post_type': mediaType == 'reel' || mediaType == 'video'
          ? 'reel'
          : mediaUrl.trim().isNotEmpty
          ? 'image'
          : 'general',
      'is_active': true,
    };
    try {
      // Attempt to write the visibility column. Falls back silently if the
      // server doesn't have it yet.
      await remote.from('posts').insert({
        ...basePayload,
        'visibility': visibility.storageValue,
      });
      _cache.clear();
      _followingCache.clear();
      _profileCaches[profileId]?.clear();
    } catch (_) {
      try {
        await remote.from('posts').insert(basePayload);
        _cache.clear();
        _followingCache.clear();
        _profileCaches[profileId]?.clear();
      } catch (error) {
        throw RepositoryFailure('تعذر نشر المنشور الآن', error);
      }
    }
  }

  @override
  Future<void> deletePost(String postId) async {
    final remote = client;
    if (remote == null || postId.isEmpty) {
      return;
    }
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        throw const RepositoryFailure('سجل الدخول أولا لحذف المنشور');
      }
      // Owner-only delete. RLS should also enforce this on the server.
      final affected = await remote
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('profile_id', profileId)
          .select('id');
      if (affected.isEmpty) {
        throw const RepositoryFailure(
          'لم يتم العثور على المنشور أو ليس لديك صلاحية حذفه',
        );
      }
      _cache.clear();
      _followingCache.clear();
      _profileCaches[profileId]?.clear();
    } on RepositoryFailure {
      rethrow;
    } catch (error) {
      throw RepositoryFailure('تعذر حذف المنشور الآن', error);
    }
  }

  @override
  Future<void> toggleLike({
    required String postId,
    required bool shouldLike,
  }) async {
    final remote = client;
    if (remote == null || postId.isEmpty) {
      return;
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        throw const RepositoryFailure('سجل الدخول أولا لإعادة النشر');
      }
      if (shouldLike) {
        await remote.from('post_likes').upsert({
          'post_id': postId,
          'profile_id': profileId,
        }, onConflict: 'post_id,profile_id');
        // Notification is emitted by the server-side `app_notify_on_post_like`
        // trigger. We intentionally don't insert from the client to avoid
        // duplicate (English + Arabic) entries.
      } else {
        await remote
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('profile_id', profileId);
      }
      // Intentionally NOT clearing the cache here: the UI already applied
      // the optimistic like flip, and re-downloading the entire feed for a
      // single like was a major source of jank.
    } catch (_) {
      // The UI already applied the optimistic state.
    }
  }

  @override
  Future<void> repost(String postId) async {
    final remote = client;
    if (remote == null || postId.isEmpty) {
      return;
    }
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        throw const RepositoryFailure('سجل الدخول أولا لإعادة النشر');
      }
      await remote.from('app_reposts').upsert({
        'target_type': 'post',
        'target_id': postId,
        'profile_id': profileId,
      }, onConflict: 'target_type,target_id,profile_id');
      await _createRepostPost(remote, postId: postId, profileId: profileId);
      _cache.clear();
      _followingCache.clear();
    } on RepositoryFailure {
      rethrow;
    } catch (error) {
      throw RepositoryFailure('تعذر إعادة النشر الآن', error);
    }
  }

  @override
  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    final remote = client;
    if (remote == null || postId.isEmpty) {
      return;
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return;
      }
      await remote.from('post_reports').upsert({
        'post_id': postId,
        'reporter_id': profileId,
        'reason': reason,
      }, onConflict: 'post_id,reporter_id');
    } catch (_) {
      // Reporting is best effort when the bridge migration is unavailable.
    }
  }

  Future<String?> _currentProfileId(SupabaseClient remote) =>
      CurrentProfileResolver.instance.resolve(client: remote);

  List<FeedPostModel> _postsFromRows(List<dynamic> rows) {
    final posts = <FeedPostModel>[];
    for (var i = 0; i < rows.length; i++) {
      final post = feedPostFromSupabase(
        Map<String, dynamic>.from(rows[i] as Map),
        colorIndex: i,
      );
      if (!post.isReel) {
        posts.add(post);
      }
    }
    return posts;
  }

  Future<void> _createRepostPost(
    SupabaseClient remote, {
    required String postId,
    required String profileId,
  }) async {
    try {
      final original = await remote
          .from('posts')
          .select(
            'content,image_url,post_type,profile_id,profiles!posts_profile_id_fkey(full_name)',
          )
          .eq('id', postId)
          .maybeSingle();
      if (original == null) {
        return;
      }
      final originalProfile = original['profiles'] is Map
          ? Map<String, dynamic>.from(original['profiles'] as Map)
          : const <String, dynamic>{};
      final originalName = '${originalProfile['full_name'] ?? 'مستخدم'}';
      final repostPayload = {
        'profile_id': profileId,
        'content': '${original['content'] ?? ''}',
        if (original['image_url'] != null) 'image_url': original['image_url'],
        'post_type': '${original['post_type'] ?? 'general'}',
        'is_active': true,
        'repost_of_post_id': postId,
        'repost_original_profile_id': original['profile_id'],
        'repost_original_name': originalName,
      };
      try {
        await remote.from('posts').insert(repostPayload);
      } catch (_) {
        await remote.from('posts').insert({
          'profile_id': profileId,
          'content':
              'إعادة نشر من $originalName\n\n${original['content'] ?? ''}',
          if (original['image_url'] != null) 'image_url': original['image_url'],
          'post_type': '${original['post_type'] ?? 'general'}',
          'is_active': true,
        });
      }
      final owner = '${original['profile_id'] ?? ''}';
      if (owner.isNotEmpty && owner != profileId) {
        await NotificationPushDispatcher.create(remote, {
          'profile_id': owner,
          'title': 'إعادة نشر',
          'message': 'تمت إعادة نشر منشورك',
          'type': 'repost',
          'action_url': 'app://post/$postId',
        });
      }
    } catch (_) {
      // The repost row itself remains the source of truth if post cloning fails.
    }
  }

}
