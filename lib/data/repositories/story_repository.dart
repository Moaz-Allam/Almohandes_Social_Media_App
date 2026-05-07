import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/story_item.dart';
import '../cache/timed_memory_cache.dart';

abstract interface class StoryRepository {
  Future<List<StoryItem>> fetchStories({bool forceRefresh = false});

  Future<void> createTextStory(String content);
}

final class SupabaseStoryRepository implements StoryRepository {
  SupabaseStoryRepository({required this.client});

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
      final rows = await remote
          .from('stories')
          .select(
            'id,profile_id,content,media_url,created_at,profiles(full_name,role)',
          )
          .eq('is_archived', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(30);
      return [
        for (var i = 0; i < rows.length; i++)
          _storyFromRow(Map<String, dynamic>.from(rows[i] as Map), i),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> createTextStory(String content) async {
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
      await remote.from('stories').insert({
        'profile_id': profileId,
        'content': trimmed,
        'media_url': 'text-story:${DateTime.now().microsecondsSinceEpoch}',
        'media_type': 'text',
      });
      _cache.clear();
    } catch (_) {
      // The UI keeps the action best-effort if the user has no active session.
    }
  }

  StoryItem _storyFromRow(Map<String, dynamic> row, int index) {
    final profile = row['profiles'] is Map
        ? Map<String, dynamic>.from(row['profiles'] as Map)
        : <String, dynamic>{};
    final name = '${profile['full_name'] ?? 'مستخدم'}'.trim();
    return StoryItem(
      id: '${row['id']}',
      name: name.isEmpty ? 'مستخدم' : name,
      content: '${row['content'] ?? ''}',
      mediaUrl: '${row['media_url'] ?? ''}',
      isNew: true,
      color: switch (index % 4) {
        0 => AppColors.blue,
        1 => AppColors.darkBlue,
        2 => AppColors.muted,
        _ => AppColors.black,
      },
    );
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
