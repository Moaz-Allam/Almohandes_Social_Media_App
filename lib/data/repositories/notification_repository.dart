import 'package:supabase_flutter/supabase_flutter.dart';

import '../session/current_profile_resolver.dart';

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

  static const _notificationPageSize = 30;

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
          .limit(_notificationPageSize);
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
      type: '${row['type'] ?? 'general'}',
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
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) {
      return '';
    }
    String two(int number) => number.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
  }

  Future<String?> _currentProfileId(SupabaseClient remote) =>
      CurrentProfileResolver.instance.resolve(client: remote);
}
