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
    String? parentId,
  });

  Future<void> toggleCommentLike({
    required String commentId,
    required bool shouldLike,
  });

  /// Resolves which post/reel/project a comment belongs to, for notification
  /// deep links of the form `app://comment/<id>`. Returns null if unknown.
  Future<({String targetType, String targetId})?> resolveCommentTarget(
    String commentId,
  );
}

final class SupabaseCommentRepository implements CommentRepository {
  SupabaseCommentRepository({required this.client});

  static const _commentsPageSize = 30;

  // Adding `app_comment_likes` introduced a SECOND relationship between
  // `app_comments` and `profiles` (the m2m likes path), so an unqualified
  // `profiles(...)` embed became ambiguous — PostgREST answers PGRST201 (HTTP
  // 300) and EVERY rich comment read/write fails, silently falling back to the
  // legacy unthreaded tables (which is why replies reverted to top-level).
  // Pinning the author embed to its FK constraint name disambiguates it.
  static const _authorEmbed =
      'profiles!app_comments_profile_id_fkey(full_name,avatar_url)';

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
    // Progressive selects so the comment thread keeps working on any of:
    //   (a) brand-new schema with parent_id + likes_count + replies_count
    //   (b) parent_id present, counters missing
    //   (c) parent_id missing
    //   (d) legacy post_comments / reel_comments fallback
    final attempts = <String>[
      'id,content,created_at,parent_id,likes_count,replies_count,$_authorEmbed',
      'id,content,created_at,parent_id,$_authorEmbed',
      'id,content,created_at,$_authorEmbed',
    ];
    List<CommentItem>? fetched;
    for (final select in attempts) {
      try {
        final rows = await remote
            .from('app_comments')
            .select(select)
            .eq('target_type', targetType)
            .eq('target_id', targetId)
            .order('created_at', ascending: false)
            .limit(_commentsPageSize);
        fetched = [
          for (var i = 0; i < rows.length; i++)
            _commentFromRow(Map<String, dynamic>.from(rows[i] as Map), i),
        ];
        break;
      } catch (_) {
        continue;
      }
    }
    fetched ??= await _fetchLegacyComments(
      remote,
      targetType: targetType,
      targetId: targetId,
    );
    if (fetched.isEmpty) {
      return fetched;
    }
    // Post-fetch enrichment: stamp `isLikedByViewer` on each comment using
    // the viewer's rows in `app_comment_likes`. PostgREST doesn't expose
    // the correlated-subquery `is_liked` field, so we do a second query
    // and merge. Falls back silently if the table is missing.
    final withLikes = await _withViewerLikes(remote, fetched);
    return _threadComments(withLikes);
  }

  /// Orders comments so each top-level comment is immediately followed by its
  /// replies (oldest reply first), instead of a flat time-ordered list. The
  /// input is newest-first, so top-level comments stay newest-first.
  List<CommentItem> _threadComments(List<CommentItem> flat) {
    final repliesByParent = <String, List<CommentItem>>{};
    for (final comment in flat) {
      if (comment.isReply) {
        repliesByParent
            .putIfAbsent(comment.parentId!, () => <CommentItem>[])
            .add(comment);
      }
    }
    for (final replies in repliesByParent.values) {
      replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    final result = <CommentItem>[];
    final seen = <String>{};
    for (final comment in flat) {
      if (comment.isReply) {
        continue;
      }
      result.add(comment);
      seen.add(comment.id);
      for (final reply in repliesByParent[comment.id] ?? const <CommentItem>[]) {
        result.add(reply);
        seen.add(reply.id);
      }
    }
    // Append any orphan replies whose parent wasn't in this page.
    for (final comment in flat) {
      if (!seen.contains(comment.id)) {
        result.add(comment);
      }
    }
    return result;
  }

  Future<List<CommentItem>> _withViewerLikes(
    SupabaseClient remote,
    List<CommentItem> comments,
  ) async {
    try {
      final viewerId = await _currentProfileId(remote);
      if (viewerId == null) {
        return comments;
      }
      final commentIds = [
        for (final comment in comments)
          if (comment.id.isNotEmpty) comment.id,
      ];
      if (commentIds.isEmpty) {
        return comments;
      }
      final rows = await remote
          .from('app_comment_likes')
          .select('comment_id')
          .eq('profile_id', viewerId)
          .inFilter('comment_id', commentIds);
      final liked = <String>{
        for (final raw in rows) '${(raw as Map)['comment_id'] ?? ''}',
      }..removeWhere((id) => id.isEmpty);
      if (liked.isEmpty) {
        return comments;
      }
      return [
        for (final comment in comments)
          liked.contains(comment.id)
              ? comment.copyWith(isLikedByViewer: true)
              : comment,
      ];
    } catch (_) {
      return comments;
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
    String? parentId,
  }) async {
    final remote = client;
    final trimmed = content.trim();
    if (remote == null || targetId.isEmpty || trimmed.isEmpty) {
      return null;
    }
    final hasParent = parentId != null && parentId.isNotEmpty;
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        throw const RepositoryFailure('سجل الدخول أولا لإرسال التعليق');
      }
      final basePayload = <String, dynamic>{
        'target_type': targetType,
        'target_id': targetId,
        'profile_id': profileId,
        'content': trimmed,
      };

      // Strategy:
      //   1) Insert with parent_id; select the rich shape.
      //   2) Insert with parent_id; select the minimal shape (rich columns
      //      missing but parent_id still persists).
      //   3) Insert without parent_id; select minimal (no schema for
      //      threaded replies — accept the comment as top-level).
      final attempts = <_InsertAttempt>[
        if (hasParent)
          _InsertAttempt(
            includeParent: true,
            select:
                'id,content,created_at,parent_id,likes_count,replies_count,$_authorEmbed',
          ),
        if (hasParent)
          _InsertAttempt(
            includeParent: true,
            select: 'id,content,created_at,parent_id,$_authorEmbed',
          ),
        _InsertAttempt(
          includeParent: false,
          select:
              'id,content,created_at,parent_id,likes_count,replies_count,$_authorEmbed',
        ),
        _InsertAttempt(
          includeParent: false,
          select: 'id,content,created_at,$_authorEmbed',
        ),
      ];

      Object? firstError;
      for (final attempt in attempts) {
        try {
          final payload = <String, dynamic>{
            ...basePayload,
            if (attempt.includeParent) 'parent_id': parentId,
          };
          final row = await remote
              .from('app_comments')
              .insert(payload)
              .select(attempt.select)
              .single();
          _caches['$targetType:$targetId']?.clear();
          return _commentFromRow(Map<String, dynamic>.from(row), 0);
        } catch (error) {
          firstError ??= error;
          continue;
        }
      }

      // None of the `app_comments` attempts worked — fall back to legacy
      // tables, which don't carry replies/likes anyway.
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
      throw RepositoryFailure(
        'تعذر إرسال التعليق الآن',
        firstError ?? 'unknown',
      );
    } on RepositoryFailure {
      rethrow;
    } catch (error) {
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
    final parentId = '${row['parent_id'] ?? ''}';
    final likesCount = int.tryParse('${row['likes_count'] ?? 0}') ?? 0;
    final repliesCount = int.tryParse('${row['replies_count'] ?? 0}') ?? 0;
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
      likesCount: likesCount,
      repliesCount: repliesCount,
      parentId: parentId.isEmpty ? null : parentId,
      isLikedByViewer: row['is_liked'] == true,
    );
  }

  @override
  Future<void> toggleCommentLike({
    required String commentId,
    required bool shouldLike,
  }) async {
    final remote = client;
    if (remote == null || commentId.isEmpty) {
      return;
    }
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return;
      }
      if (shouldLike) {
        await remote.from('app_comment_likes').upsert({
          'comment_id': commentId,
          'profile_id': profileId,
        }, onConflict: 'comment_id,profile_id');
      } else {
        await remote
            .from('app_comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('profile_id', profileId);
      }
    } catch (_) {
      // app_comment_likes is optional on older deployments; the UI keeps
      // the optimistic toggle either way.
    }
  }

  @override
  Future<({String targetType, String targetId})?> resolveCommentTarget(
    String commentId,
  ) async {
    final remote = client;
    if (remote == null || commentId.isEmpty) {
      return null;
    }
    try {
      final row = await remote
          .from('app_comments')
          .select('target_type,target_id')
          .eq('id', commentId)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      final targetType = '${row['target_type'] ?? ''}'.trim();
      final targetId = '${row['target_id'] ?? ''}'.trim();
      if (targetType.isEmpty || targetId.isEmpty) {
        return null;
      }
      return (targetType: targetType, targetId: targetId);
    } catch (_) {
      return null;
    }
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

class _InsertAttempt {
  const _InsertAttempt({required this.includeParent, required this.select});

  final bool includeParent;
  final String select;
}
