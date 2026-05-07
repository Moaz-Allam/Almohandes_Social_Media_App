import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_item_model.dart';
import '../cache/timed_memory_cache.dart';

abstract interface class NotificationRepository {
  Future<List<NotificationItemModel>> fetchNotifications({
    bool forceRefresh = false,
  });

  Future<void> markRead(String notificationId);

  Future<void> delete(String notificationId);
}

final class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository({required this.client});

  final SupabaseClient? client;
  final _cache = TimedMemoryCache<List<NotificationItemModel>>(
    ttl: const Duration(seconds: 30),
  );

  @override
  Future<List<NotificationItemModel>> fetchNotifications({
    bool forceRefresh = false,
  }) {
    return _cache.read(_fetchNotifications, forceRefresh: forceRefresh);
  }

  @override
  Future<void> markRead(String notificationId) async {
    final remote = client;
    if (remote == null || notificationId.isEmpty) {
      return;
    }
    try {
      await remote
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      _cache.clear();
    } catch (_) {
      // Optional table operation; the list will refresh when the backend allows it.
    }
  }

  @override
  Future<void> delete(String notificationId) async {
    final remote = client;
    if (remote == null || notificationId.isEmpty) {
      return;
    }
    try {
      await remote.from('notifications').delete().eq('id', notificationId);
      _cache.clear();
    } catch (_) {
      // Optional table operation; the UI keeps the list stable on failure.
    }
  }

  Future<List<NotificationItemModel>> _fetchNotifications() async {
    final remote = client;
    if (remote == null) {
      return const [];
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return const [];
      }
      final rows = await remote
          .from('notifications')
          .select('id,title,message,type,is_read,action_url,created_at')
          .eq('profile_id', profileId)
          .order('created_at', ascending: false)
          .limit(50);
      return [
        for (var i = 0; i < rows.length; i++)
          _notificationFromRow(Map<String, dynamic>.from(rows[i] as Map), i),
      ];
    } catch (_) {
      return const [];
    }
  }

  NotificationItemModel _notificationFromRow(
    Map<String, dynamic> row,
    int index,
  ) {
    return NotificationItemModel(
      id: '${row['id']}',
      title: '${row['title'] ?? ''}',
      preview: '${row['message'] ?? ''}',
      time: _timeLabel(row['created_at']),
      unread: row['is_read'] != true,
      actionUrl: row['action_url'] == null ? null : '${row['action_url']}',
      color: switch (index % 4) {
        0 => AppColors.blue,
        1 => AppColors.darkBlue,
        2 => AppColors.muted,
        _ => AppColors.black,
      },
    );
  }

  String _timeLabel(Object? value) {
    final date = DateTime.tryParse('$value');
    if (date == null) {
      return '';
    }
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return 'قبل ${diff.inMinutes.clamp(1, 59)} د';
    }
    if (diff.inHours < 24) {
      return 'قبل ${diff.inHours} س';
    }
    return 'قبل ${diff.inDays} يوم';
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
