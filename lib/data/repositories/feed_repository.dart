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

  Future<void> createPost({
    required String content,
    String mediaUrl = '',
    String mediaType = 'text',
  });

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
      return _postsFromRows(rows);
    } catch (_) {
      try {
        final rows = await remote
            .from('posts')
            .select(
              'id,content,image_url,post_type,likes_count,comments_count,created_at,repost_of_post_id,repost_original_profile_id,repost_original_name,profiles(full_name,role,avatar_url)',
            )
            .eq('is_active', true)
            .eq('is_archived', false)
            .order('created_at', ascending: false)
            .limit(_feedPageSize);
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
            'id,profile_id,content,image_url,post_type,likes_count,comments_count,created_at,repost_of_post_id,repost_original_profile_id,repost_original_name,profiles(full_name,role,avatar_url)',
          )
          .eq('profile_id', profileId)
          .eq('is_active', true)
          .eq('is_archived', false)
          .order('created_at', ascending: false)
          .limit(_profilePageSize);
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
  Future<void> createPost({
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
        throw const RepositoryFailure('سجل الدخول أولا لنشر المنشور');
      }
      await remote.from('posts').insert({
        'profile_id': profileId,
        'content': trimmed,
        if (mediaUrl.trim().isNotEmpty) 'image_url': mediaUrl.trim(),
        'post_type': mediaType == 'reel' || mediaType == 'video'
            ? 'reel'
            : mediaUrl.trim().isNotEmpty
            ? 'image'
            : 'general',
        'is_active': true,
      });
      _cache.clear();
      _profileCaches[profileId]?.clear();
    } catch (error) {
      throw RepositoryFailure('تعذر نشر المنشور الآن', error);
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
        await _notifyPostOwner(
          remote,
          postId: postId,
          actorProfileId: profileId,
          title: 'إعجاب جديد',
          message: 'تلقى منشورك إعجابا جديدا',
          type: 'like',
        );
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
        await remote.from('notifications').insert({
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

  Future<void> _notifyPostOwner(
    SupabaseClient remote, {
    required String postId,
    required String actorProfileId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final row = await remote
          .from('posts')
          .select('profile_id')
          .eq('id', postId)
          .maybeSingle();
      final owner = row == null ? '' : '${row['profile_id'] ?? ''}';
      if (owner.isEmpty || owner == actorProfileId) {
        return;
      }
      await remote.from('notifications').insert({
        'profile_id': owner,
        'title': title,
        'message': message,
        'type': type,
        'action_url': 'app://post/$postId',
      });
    } catch (_) {
      // Notifications are best-effort.
    }
  }
}
