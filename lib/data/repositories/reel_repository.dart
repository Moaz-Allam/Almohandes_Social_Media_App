import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/reel_item.dart';
import '../cache/timed_memory_cache.dart';
import '../notifications/notification_push_dispatcher.dart';
import 'repository_failure.dart';

abstract interface class ReelRepository {
  Future<List<ReelItem>> fetchReels({bool forceRefresh = false});

  Future<void> createReel({required String caption, required String videoUrl});

  Future<void> toggleLike({required String reelId, required bool shouldLike});

  Future<void> repost(String reelId);
}

final class SupabaseReelRepository implements ReelRepository {
  SupabaseReelRepository({required this.client});

  static const _reelsPageSize = 12;

  final SupabaseClient? client;
  final _cache = TimedMemoryCache<List<ReelItem>>(
    ttl: const Duration(minutes: 1),
  );

  @override
  Future<List<ReelItem>> fetchReels({bool forceRefresh = false}) {
    return _cache.read(_fetchReels, forceRefresh: forceRefresh);
  }

  Future<List<ReelItem>> _fetchReels() async {
    final remote = client;
    if (remote == null) {
      return const [];
    }

    try {
      final rows = await remote
          .from('reels')
          .select(
            'id,profile_id,video_url,thumbnail_url,caption,likes_count,comments_count,shares_count,profiles(full_name,role,avatar_url)',
          )
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(_reelsPageSize);
      return [
        for (var i = 0; i < rows.length; i++)
          _reelFromRow(Map<String, dynamic>.from(rows[i] as Map), i),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> createReel({
    required String caption,
    required String videoUrl,
  }) async {
    final remote = client;
    if (remote == null || videoUrl.trim().isEmpty) {
      return;
    }
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        throw const RepositoryFailure('سجل الدخول أولا لنشر الريل');
      }
      await remote.from('reels').insert({
        'profile_id': profileId,
        'video_url': videoUrl.trim(),
        'thumbnail_url': videoUrl.trim(),
        'caption': caption.trim(),
        'is_active': true,
      });
      _cache.clear();
    } on RepositoryFailure {
      rethrow;
    } catch (error) {
      throw RepositoryFailure('تعذر نشر الريل الآن', error);
    }
  }

  @override
  Future<void> toggleLike({
    required String reelId,
    required bool shouldLike,
  }) async {
    final remote = client;
    if (remote == null || reelId.isEmpty) {
      return;
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        throw const RepositoryFailure('سجل الدخول أولا لإعادة نشر الريل');
      }
      if (shouldLike) {
        await remote.from('reel_likes').upsert({
          'reel_id': reelId,
          'profile_id': profileId,
        }, onConflict: 'reel_id,profile_id');
        await _notifyReelOwner(
          remote,
          reelId: reelId,
          actorProfileId: profileId,
          title: 'إعجاب جديد',
          message: 'تلقى الريل إعجابا جديدا',
          type: 'like',
        );
      } else {
        await remote
            .from('reel_likes')
            .delete()
            .eq('reel_id', reelId)
            .eq('profile_id', profileId);
      }
      _cache.clear();
    } catch (_) {
      // Optimistic UI already reflects the tap.
    }
  }

  @override
  Future<void> repost(String reelId) async {
    final remote = client;
    if (remote == null || reelId.isEmpty) {
      return;
    }
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return;
      }
      await remote.from('app_reposts').upsert({
        'target_type': 'reel',
        'target_id': reelId,
        'profile_id': profileId,
      }, onConflict: 'target_type,target_id,profile_id');
      await _notifyReelOwner(
        remote,
        reelId: reelId,
        actorProfileId: profileId,
        title: 'إعادة نشر',
        message: 'تمت إعادة نشر الريل',
        type: 'repost',
      );
      _cache.clear();
    } on RepositoryFailure {
      rethrow;
    } catch (error) {
      throw RepositoryFailure('تعذر إعادة نشر الريل الآن', error);
    }
  }

  ReelItem _reelFromRow(Map<String, dynamic> row, int index) {
    final profile = row['profiles'] is Map
        ? Map<String, dynamic>.from(row['profiles'] as Map)
        : <String, dynamic>{};
    final name = '${profile['full_name'] ?? 'مستخدم'}'.trim();
    final role = '${profile['role'] ?? ''}';
    return ReelItem(
      id: '${row['id']}',
      profileId: '${row['profile_id']}',
      name: name.isEmpty ? 'مستخدم' : name,
      headline: _headlineForRole(role),
      caption: '${row['caption'] ?? ''}',
      likesCount: _intFrom(row['likes_count']),
      commentsCount: _intFrom(row['comments_count']),
      repostsCount: _intFrom(row['shares_count']),
      videoUrl: row['video_url'] == null ? null : '${row['video_url']}',
      thumbnailUrl: row['thumbnail_url'] == null
          ? null
          : '${row['thumbnail_url']}',
      avatarUrl: profile['avatar_url'] == null
          ? null
          : '${profile['avatar_url']}',
      color: switch (index % 4) {
        0 => AppColors.blue,
        1 => AppColors.darkBlue,
        2 => AppColors.muted,
        _ => AppColors.black,
      },
    );
  }

  int _intFrom(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }

  String _headlineForRole(String role) {
    return switch (role) {
      'engineer' => 'مهندس',
      'contractor' || 'client' => 'شركة مشاريع',
      'craftsman' => 'حرفي',
      'worker' => 'عامل',
      'machinery' => 'مزود آليات',
      _ => 'مستخدم',
    };
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

  Future<void> _notifyReelOwner(
    SupabaseClient remote, {
    required String reelId,
    required String actorProfileId,
    required String title,
    required String message,
    required String type,
  }) async {
    try {
      final row = await remote
          .from('reels')
          .select('profile_id')
          .eq('id', reelId)
          .maybeSingle();
      final owner = row == null ? '' : '${row['profile_id'] ?? ''}';
      if (owner.isEmpty || owner == actorProfileId) {
        return;
      }
      await NotificationPushDispatcher.create(remote, {
        'profile_id': owner,
        'title': title,
        'message': message,
        'type': type,
        'action_url': 'app://reel/$reelId',
      });
    } catch (_) {
      // Notifications are best-effort.
    }
  }
}
