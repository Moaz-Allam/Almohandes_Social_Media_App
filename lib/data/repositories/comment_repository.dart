import 'package:flutter/material.dart' show Color;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../session/current_profile_resolver.dart';

import '../../core/constants/app_colors.dart';
import '../../models/comment_item.dart';
import '../cache/timed_memory_cache.dart';
import '../notifications/notification_push_dispatcher.dart';
import 'repository_failure.dart';

abstract interface class CommentRepository {
  Future<List<CommentItem>> fetchComments({
    required String targetType,
    required String targetId,
    bool forceRefresh = false,
  });

  Future<CommentItem?> addComment({
    required String targetType,
    required String targetId,
    required String content,
  });
}

final class SupabaseCommentRepository implements CommentRepository {
  SupabaseCommentRepository({required this.client});

  static const _commentsPageSize = 30;

  final SupabaseClient? client;
  final _caches = <String, TimedMemoryCache<List<CommentItem>>>{};

  @override
  Future<List<CommentItem>> fetchComments({
    required String targetType,
    required String targetId,
    bool forceRefresh = false,
  }) {
    final key = '$targetType:$targetId';
    final cache = _caches.putIfAbsent(
      key,
      () =>
          TimedMemoryCache<List<CommentItem>>(ttl: const Duration(seconds: 20)),
    );
    return cache.read(
      () => _fetchComments(targetType: targetType, targetId: targetId),
      forceRefresh: forceRefresh,
    );
  }

  Future<List<CommentItem>> _fetchComments({
    required String targetType,
    required String targetId,
  }) async {
    final remote = client;
    if (remote == null || targetId.isEmpty) {
      return const [];
    }
    try {
      final rows = await remote
          .from('app_comments')
          .select('id,content,created_at,profiles(full_name,avatar_url)')
          .eq('target_type', targetType)
          .eq('target_id', targetId)
          .order('created_at', ascending: false)
          .limit(_commentsPageSize);
      return [
        for (var i = 0; i < rows.length; i++)
          _commentFromRow(Map<String, dynamic>.from(rows[i] as Map), i),
      ];
    } catch (_) {
      return _fetchLegacyComments(
        remote,
        targetType: targetType,
        targetId: targetId,
      );
    }
  }

  Future<List<CommentItem>> _fetchLegacyComments(
    SupabaseClient remote, {
    required String targetType,
    required String targetId,
  }) async {
    final attempts = targetType == 'reel'
        ? const [('reel_comments', 'reel_id'), ('comments', 'reel_id')]
        : const [('post_comments', 'post_id'), ('comments', 'post_id')];
    for (final attempt in attempts) {
      try {
        final rows = await remote
            .from(attempt.$1)
            .select('id,content,created_at,profiles(full_name,avatar_url)')
            .eq(attempt.$2, targetId)
            .order('created_at', ascending: false)
            .limit(_commentsPageSize);
        return [
          for (var i = 0; i < rows.length; i++)
            _commentFromRow(Map<String, dynamic>.from(rows[i] as Map), i),
        ];
      } catch (_) {
        continue;
      }
    }
    return const [];
  }

  @override
  Future<CommentItem?> addComment({
    required String targetType,
    required String targetId,
    required String content,
  }) async {
    final remote = client;
    final trimmed = content.trim();
    if (remote == null || targetId.isEmpty || trimmed.isEmpty) {
      return null;
    }
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        throw const RepositoryFailure('سجل الدخول أولا لإرسال التعليق');
      }
      final row = await remote
          .from('app_comments')
          .insert({
            'target_type': targetType,
            'target_id': targetId,
            'profile_id': profileId,
            'content': trimmed,
          })
          .select('id,content,created_at,profiles(full_name,avatar_url)')
          .single();
      final key = '$targetType:$targetId';
      _caches[key]?.clear();
      await _notifyCommentTargetOwner(
        remote,
        targetType: targetType,
        targetId: targetId,
        actorProfileId: profileId,
      );
      return _commentFromRow(Map<String, dynamic>.from(row), 0);
    } catch (error) {
      try {
        final profileId = await _currentProfileId(remote);
        if (profileId == null) {
          throw const RepositoryFailure('سجل الدخول أولا لإرسال التعليق');
        }
        final inserted = await _insertLegacyComment(
          remote,
          profileId: profileId,
          targetType: targetType,
          targetId: targetId,
          content: trimmed,
        );
        if (inserted != null) {
          _caches['$targetType:$targetId']?.clear();
          await _notifyCommentTargetOwner(
            remote,
            targetType: targetType,
            targetId: targetId,
            actorProfileId: profileId,
          );
          return inserted;
        }
      } catch (_) {
        // Report a clean app message below.
      }
      throw RepositoryFailure('تعذر إرسال التعليق الآن', error);
    }
  }

  Future<CommentItem?> _insertLegacyComment(
    SupabaseClient remote, {
    required String profileId,
    required String targetType,
    required String targetId,
    required String content,
  }) async {
    final attempts = targetType == 'reel'
        ? const [('reel_comments', 'reel_id'), ('comments', 'reel_id')]
        : const [('post_comments', 'post_id'), ('comments', 'post_id')];
    for (final attempt in attempts) {
      try {
        final row = await remote
            .from(attempt.$1)
            .insert({
              attempt.$2: targetId,
              'profile_id': profileId,
              'content': content,
            })
            .select('id,content,created_at,profiles(full_name,avatar_url)')
            .single();
        return _commentFromRow(Map<String, dynamic>.from(row), 0);
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  CommentItem _commentFromRow(Map<String, dynamic> row, int index) {
    final profile = row['profiles'] is Map
        ? Map<String, dynamic>.from(row['profiles'] as Map)
        : const <String, dynamic>{};
    final authorName = '${profile['full_name'] ?? 'مستخدم'}'.trim();
    return CommentItem(
      id: '${row['id']}',
      authorName: authorName.isEmpty ? 'مستخدم' : authorName,
      content: '${row['content'] ?? ''}',
      createdAt:
          DateTime.tryParse('${row['created_at']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      color: _colorForIndex(index),
      avatarUrl: profile['avatar_url'] == null
          ? null
          : '${profile['avatar_url']}',
    );
  }

  Color _colorForIndex(int index) {
    return switch (index % 4) {
      0 => AppColors.blue,
      1 => AppColors.darkBlue,
      2 => AppColors.muted,
      _ => AppColors.black,
    };
  }

  Future<String?> _currentProfileId(SupabaseClient remote) =>
      CurrentProfileResolver.instance.resolve(client: remote);

  Future<void> _notifyCommentTargetOwner(
    SupabaseClient remote, {
    required String targetType,
    required String targetId,
    required String actorProfileId,
  }) async {
    try {
      final table = switch (targetType) {
        'reel' => 'reels',
        'project' => 'projects',
        _ => 'posts',
      };
      final row = await remote
          .from(table)
          .select('profile_id')
          .eq('id', targetId)
          .maybeSingle();
      final owner = row == null ? '' : '${row['profile_id'] ?? ''}';
      if (owner.isEmpty || owner == actorProfileId) {
        return;
      }
      await NotificationPushDispatcher.create(remote, {
        'profile_id': owner,
        'title': 'تعليق جديد',
        'message': 'تمت إضافة تعليق جديد',
        'type': 'comment',
        'action_url': 'app://$targetType/$targetId',
      });
    } catch (_) {
      // Notifications are best-effort.
    }
  }
}
