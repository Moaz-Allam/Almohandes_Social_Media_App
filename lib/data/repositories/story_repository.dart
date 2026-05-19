import 'package:supabase_flutter/supabase_flutter.dart';

import '../session/current_profile_resolver.dart';

import '../../core/constants/app_colors.dart';
import '../../models/story_item.dart';
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
      final rows = await remote
          .from('stories')
          .select(
            'id,profile_id,content,media_url,media_type,created_at,profiles(full_name,role,avatar_url)',
          )
          .eq('is_archived', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false)
          .limit(_storiesPageSize);
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
