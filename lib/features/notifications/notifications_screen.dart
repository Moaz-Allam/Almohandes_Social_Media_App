import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_item_model.dart';
import '../../state/app_scope.dart';
import '../home/widgets/home_top_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _itemsFuture = Future.value(const <NotificationItemModel>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _itemsFuture = AppScope.read(
      context,
    ).repositories.notifications.fetchNotifications();
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
    unawaited(
      app.repositories.notifications.markRead(item.id).then((_) {
        if (mounted) {
          return _refresh();
        }
      }),
    );
  }

  void _delete(NotificationItemModel item) {
    final app = AppScope.read(context);
    setState(() {
      _deletedNotificationIds.add(item.id);
    });
    app.notifyNotificationStateChanged();
    unawaited(app.repositories.notifications.delete(item.id));
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
              return RefreshIndicator(
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
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
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
