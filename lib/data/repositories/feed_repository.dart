import 'package:supabase_flutter/supabase_flutter.dart';

import '../session/current_profile_resolver.dart';

import '../../models/feed_post_model.dart';
import '../../models/post_visibility.dart';
import '../cache/timed_memory_cache.dart';
import '../mappers/feed_mapper.dart';
import '../notifications/notification_push_dispatcher.dart';
import 'repository_failure.dart';

abstract interface class FeedRepository {
  Future<List<FeedPostModel>> fetchHomeFeed({bool forceRefresh = false});

  /// Returns home-feed posts authored by profiles the viewer follows.
  Future<List<FeedPostModel>> fetchFollowingFeed({bool forceRefresh = false});

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

  final SupabaseClient? client;
  final _cache = TimedMemoryCache<List<FeedPostModel>>(
    ttl: const Duration(minutes: 1),
  );
  final _followingCache = TimedMemoryCache<List<FeedPostModel>>(
    ttl: const Duration(minutes: 1),
  );
  // LRU cap: per-profile post caches are useful for the recently-viewed
  // profiles only. Without a cap, browsing through many profiles leaks one
  // cache (with image URL lists + decoded data) per profile id for the
  // lifetime of the app.
  static const _maxProfileCaches = 16;
  final _profileCaches = <String, TimedMemoryCache<List<FeedPostModel>>>{};

  @override
  Future<List<FeedPostModel>> fetchHomeFeed({bool forceRefresh = false}) async {
    return _cache.read(_fetchHomeFeed, forceRefresh: forceRefresh);
  }

  Future<List<FeedPostModel>> _fetchHomeFeed() async {
    final remote = client;
    if (remote == null) {
      return const [];
    }

    try {
      final profileId = await _currentProfileId(remote);
      final params = <String, dynamic>{'p_limit': _feedPageSize};
      if (profileId != null) {
        params['p_profile_id'] = profileId;
      }
      final rows = await remote.rpc<List<dynamic>>(
        'get_home_feed',
        params: params,
      );
      return _enforceVisibility(remote, _postsFromRows(rows));
    } catch (_) {
      try {
        final rows = await remote
            .from('posts')
            .select(
              'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,visibility,repost_of_post_id,repost_original_profile_id,repost_original_name,profiles(full_name,role,avatar_url)',
            )
            .eq('is_active', true)
            .eq('is_archived', false)
            .order('created_at', ascending: false)
            .limit(_feedPageSize);
        return _enforceVisibility(remote, _postsFromRows(rows));
      } catch (_) {
        try {
          final rows = await remote
              .from('posts')
              .select(
                'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,profiles(full_name,role,avatar_url)',
              )
              .eq('is_active', true)
              .order('created_at', ascending: false)
              .limit(_feedPageSize);
          return _enforceVisibility(remote, _postsFromRows(rows));
        } catch (_) {
          return const [];
        }
      }
    }
  }

  @override
  Future<List<FeedPostModel>> fetchFollowingFeed({
    bool forceRefresh = false,
  }) {
    return _followingCache.read(
      _fetchFollowingFeed,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<FeedPostModel>> _fetchFollowingFeed() async {
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
            'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,visibility,repost_of_post_id,repost_original_profile_id,repost_original_name,profiles(full_name,role,avatar_url)',
          )
          .inFilter('profile_id', followedIds.toList())
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(_feedPageSize);
      return _enforceVisibility(remote, _postsFromRows(rows));
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
              'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,profiles(full_name,role,avatar_url)',
            )
            .inFilter('profile_id', followedIds.toList())
            .eq('is_active', true)
            .order('created_at', ascending: false)
            .limit(_feedPageSize);
        return _enforceVisibility(remote, _postsFromRows(rows));
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
    final posts = await _fetchProfilePostsRaw(remote, profileId);
    return _enforceVisibility(remote, posts);
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
        'profiles(full_name,role,avatar_url)';
    const baseSelect =
        'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,'
        'profiles(full_name,role,avatar_url)';
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

  /// Hide posts whose author flagged them as connections-only when the
  /// viewer isn't the author or an accepted connection. The
  /// 20260521150000 migration adds a SELECT RLS that does the same job on
  /// the server, but the client filter keeps older deployments correct.
  Future<List<FeedPostModel>> _enforceVisibility(
    SupabaseClient remote,
    List<FeedPostModel> posts,
  ) async {
    if (posts.isEmpty) {
      return posts;
    }
    final hasPrivate =
        posts.any((post) => post.visibility == PostVisibility.private);
    if (!hasPrivate) {
      return posts;
    }
    final viewerId = await _currentProfileId(remote);
    final connectionIds = await _acceptedConnectionIds(remote, viewerId);
    return [
      for (final post in posts)
        if (post.visibility == PostVisibility.public ||
            (viewerId != null && post.profileId == viewerId) ||
            (post.profileId != null &&
                connectionIds.contains(post.profileId)))
          post,
    ];
  }

  Future<Set<String>> _acceptedConnectionIds(
    SupabaseClient remote,
    String? viewerId,
  ) async {
    if (viewerId == null) {
      return const <String>{};
    }
    try {
      final asRequester = await remote
          .from('connection_requests')
          .select('receiver_profile_id')
          .eq('requester_profile_id', viewerId)
          .eq('status', 'accepted');
      final asReceiver = await remote
          .from('connection_requests')
          .select('requester_profile_id')
          .eq('receiver_profile_id', viewerId)
          .eq('status', 'accepted');
      return <String>{
        for (final raw in asRequester)
          '${(raw as Map)['receiver_profile_id'] ?? ''}',
        for (final raw in asReceiver)
          '${(raw as Map)['requester_profile_id'] ?? ''}',
      }..removeWhere((id) => id.isEmpty);
    } catch (_) {
      return const <String>{};
    }
  }

  Future<void> _createRepostPost(
    SupabaseClient remote, {
    required String postId,
    required String profileId,
  }) async {
    try {
      final original = await remote
          .from('posts')
          .select('content,image_url,post_type,profile_id,profiles(full_name)')
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
