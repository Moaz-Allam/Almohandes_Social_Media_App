import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/reel_item.dart';
import '../cache/timed_memory_cache.dart';

abstract interface class ReelRepository {
  Future<List<ReelItem>> fetchReels({bool forceRefresh = false});

  Future<void> toggleLike({required String reelId, required bool shouldLike});
}

final class SupabaseReelRepository implements ReelRepository {
  SupabaseReelRepository({required this.client});

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
            'id,profile_id,video_url,thumbnail_url,caption,likes_count,comments_count,shares_count,profiles(full_name,role)',
          )
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(40);
      return [
        for (var i = 0; i < rows.length; i++)
          _reelFromRow(Map<String, dynamic>.from(rows[i] as Map), i),
      ];
    } catch (_) {
      return const [];
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
        return;
      }
      if (shouldLike) {
        await remote.from('reel_likes').upsert({
          'reel_id': reelId,
          'profile_id': profileId,
        }, onConflict: 'reel_id,profile_id');
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
      'engineer' => 'مهندس · منصة المهندس',
      'contractor' || 'client' => 'شركة مشاريع',
      'craftsman' => 'حرفي',
      'worker' => 'عامل',
      'machinery' => 'مزود آليات',
      _ => 'منصة المهندس',
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
}
