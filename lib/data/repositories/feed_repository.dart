import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/feed_post_model.dart';
import '../cache/timed_memory_cache.dart';
import '../mappers/feed_mapper.dart';
import 'repository_failure.dart';

abstract interface class FeedRepository {
  Future<List<FeedPostModel>> fetchHomeFeed({bool forceRefresh = false});

  Future<List<FeedPostModel>> fetchProfilePosts(
    String profileId, {
    bool forceRefresh = false,
  });

  Future<void> createPost({required String content});

  Future<void> toggleLike({required String postId, required bool shouldLike});

  Future<void> reportPost({required String postId, required String reason});
}

final class SupabaseFeedRepository implements FeedRepository {
  SupabaseFeedRepository({required this.client});

  final SupabaseClient? client;
  final _cache = TimedMemoryCache<List<FeedPostModel>>(
    ttl: const Duration(minutes: 1),
  );
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
      final params = <String, dynamic>{'p_limit': 50};
      if (profileId != null) {
        params['p_profile_id'] = profileId;
      }
      final rows = await remote.rpc<List<dynamic>>(
        'get_home_feed',
        params: params,
      );
      return [
        for (var i = 0; i < rows.length; i++)
          feedPostFromSupabase(
            Map<String, dynamic>.from(rows[i] as Map),
            colorIndex: i,
          ),
      ];
    } catch (_) {
      try {
        final rows = await remote
            .from('posts')
            .select(
              'id,content,image_url,likes_count,comments_count,created_at,profiles(full_name,role)',
            )
            .eq('is_active', true)
            .eq('is_archived', false)
            .order('created_at', ascending: false)
            .limit(50);
        return [
          for (var i = 0; i < rows.length; i++)
            feedPostFromSupabase(
              Map<String, dynamic>.from(rows[i] as Map),
              colorIndex: i,
            ),
        ];
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
    final cache = _profileCaches.putIfAbsent(
      profileId,
      () => TimedMemoryCache<List<FeedPostModel>>(
        ttl: const Duration(minutes: 1),
      ),
    );
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

    try {
      final rows = await remote
          .from('posts')
          .select(
            'id,profile_id,content,image_url,likes_count,comments_count,created_at,profiles(full_name,role)',
          )
          .eq('profile_id', profileId)
          .eq('is_active', true)
          .eq('is_archived', false)
          .order('created_at', ascending: false)
          .limit(60);
      return [
        for (var i = 0; i < rows.length; i++)
          feedPostFromSupabase(
            Map<String, dynamic>.from(rows[i] as Map),
            colorIndex: i,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> createPost({required String content}) async {
    final remote = client;
    final trimmed = content.trim();
    if (remote == null || trimmed.isEmpty) {
      return;
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return;
      }
      await remote.from('posts').insert({
        'profile_id': profileId,
        'content': trimmed,
        'post_type': 'general',
        'is_active': true,
      });
      _cache.clear();
      _profileCaches[profileId]?.clear();
    } catch (error) {
      throw RepositoryFailure('تعذر نشر المنشور في Supabase', error);
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
        return;
      }
      if (shouldLike) {
        await remote.from('post_likes').upsert({
          'post_id': postId,
          'profile_id': profileId,
        }, onConflict: 'post_id,profile_id');
      } else {
        await remote
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('profile_id', profileId);
      }
      _cache.clear();
    } catch (_) {
      // The UI already applied the optimistic state.
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

  Future<String?> _currentProfileId(SupabaseClient remote) async {
    final userId = remote.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    final row = await remote
        .from('profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : '${row['id']}';
  }
}
