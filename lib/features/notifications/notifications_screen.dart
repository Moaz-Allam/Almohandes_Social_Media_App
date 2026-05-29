import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_item_model.dart';
import '../../state/app_scope.dart';
import '../home/widgets/home_top_bar.dart';
import 'notification_action_router.dart';
import 'widgets/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.onMenu,
    required this.onMessages,
  });

  final VoidCallback onMenu;
  final VoidCallback onMessages;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<NotificationItemModel>> _itemsFuture;
  final Set<String> _deletedNotificationIds = {};
  final Set<String> _readNotificationIds = {};
  bool _didStartLoading = false;
  int _lastRealtimeVersion = 0;

  @override
  void initState() {
    super.initState();
    _itemsFuture = Future.value(const <NotificationItemModel>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Watch the realtime counter: refetch when the server pushes a new or
    // updated notification for this user.
    final controller = AppScope.watch(context);
    final version = controller.realtimeNotificationVersion;
    if (_didStartLoading && _lastRealtimeVersion == version) {
      return;
    }
    final isLiveUpdate = _didStartLoading;
    _didStartLoading = true;
    _lastRealtimeVersion = version;
    _itemsFuture = controller.repositories.notifications.fetchNotifications(
      forceRefresh: isLiveUpdate,
    );
  }

  Future<void> _refresh({bool forceRefresh = true}) async {
    setState(() {
      _itemsFuture = AppScope.read(context).repositories.notifications
          .fetchNotifications(forceRefresh: forceRefresh);
    });
    await _itemsFuture;
  }

  void _markRead(NotificationItemModel item) {
    final app = AppScope.read(context);
    setState(() {
      _readNotificationIds.add(item.id);
    });
    app.notifyNotificationStateChanged();
    // Fire-and-forget. The optimistic _readNotificationIds set already
    // covers the UI; no need to re-fetch the entire list.
    unawaited(app.repositories.notifications.markRead(item.id));
  }

  Future<void> _open(NotificationItemModel item) async {
    // Mark read optimistically so the tap also clears the unread state.
    if (item.unread) {
      _markRead(item);
    }
    await openNotificationAction(context, item.actionUrl);
  }

  void _delete(NotificationItemModel item) {
    final app = AppScope.read(context);
    setState(() {
      _deletedNotificationIds.add(item.id);
    });
    app.notifyNotificationStateChanged();
    unawaited(app.repositories.notifications.delete(item.id));
  }

  void _markAllRead(List<NotificationItemModel> items) {
    final unreadIds = [
      for (final item in items)
        if (item.unread) item.id,
    ];
    if (unreadIds.isEmpty) {
      return;
    }
    final app = AppScope.read(context);
    setState(() {
      _readNotificationIds.addAll(unreadIds);
    });
    app.notifyNotificationStateChanged();
    // The optimistic _readNotificationIds set already clears the UI; the bulk
    // update keeps the backend in sync in a single round trip.
    unawaited(app.repositories.notifications.markAllRead());
  }

  List<NotificationItemModel> _visibleItems(List<NotificationItemModel> items) {
    return [
      for (final item in items)
        if (!_deletedNotificationIds.contains(item.id))
          _readNotificationIds.contains(item.id)
              ? item.copyWith(unread: false)
              : item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeTopBar(onMenu: widget.onMenu, onMessages: widget.onMessages),
        Expanded(
          child: FutureBuilder<List<NotificationItemModel>>(
            future: _itemsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = _visibleItems(
                snapshot.data ?? const <NotificationItemModel>[],
              );
              if (items.isEmpty) {
                return const _NotificationsEmptyState();
              }
              final hasUnread = items.any((item) => item.unread);
              return Column(
                children: [
                  if (hasUnread)
                    _MarkAllReadBar(onPressed: () => _markAllRead(items)),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return NotificationTile(
                            item: item,
                            onMarkRead: () => _markRead(item),
                            onDelete: () => _delete(item),
                            onTap: () => _open(item),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MarkAllReadBar extends StatelessWidget {
  const _MarkAllReadBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: AlignmentDirectional.centerStart,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.done_all, size: 18, color: AppColors.blue),
        label: const Text(
          'تحديد الكل كمقروء',
          style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none, color: AppColors.muted, size: 46),
            SizedBox(height: 12),
            Text(
              'لا توجد إشعارات بعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text(
              'ستظهر إشعاراتك هنا عند وصولها.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
