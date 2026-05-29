import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/layout_breakpoints.dart';
import '../../../models/message_item.dart';
import '../../../models/notification_item_model.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../state/app_scope.dart';
import '../../messages/messages_screen.dart';
import '../../notifications/notification_action_router.dart';
import '../../notifications/notifications_screen.dart';

/// Mobile top bar styled after the web dashboard's header:
/// avatar + name/location block on the right (RTL), action icons on the
/// left, surface-tinted background with a soft bottom divider.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.onMenu,
    required this.onMessages,
    this.hint = 'بحث',
  });

  final VoidCallback onMenu;
  final VoidCallback onMessages;
  final String hint;

  @override
  Widget build(BuildContext context) {
    if (LayoutBreakpoints.isDesktop(context)) {
      return const SizedBox.shrink();
    }
    final profile = AppScope.watch(context).profile;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : 'المستخدم';
    final location = (profile?.location.isNotEmpty ?? false)
        ? profile!.location
        : 'العراق';

    return SafeArea(
      bottom: false,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: context.appSurface,
          border: Border(
            bottom: BorderSide(color: context.appBorder.withValues(alpha: 0.6)),
          ),
        ),
        child: Row(
          children: [
            // RTL start (visual right): avatar + name.
            GestureDetector(
              onTap: onMenu,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.appPrimary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(2),
                child: AppAvatar(
                  name: name,
                  radius: 20,
                  color: context.appPrimary,
                  imageUrl: profile?.avatarUrl,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: context.appMuted,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      location,
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            // RTL end (visual left): live, messages, notifications.
            const _LivePill(),
            const SizedBox(width: 6),
            _MessagesIcon(onMessages: onMessages),
            const SizedBox(width: 6),
            const _NotificationsIcon(),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appSurfaceAlt.withValues(alpha: 0.6),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: tooltip ?? '',
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, size: 22, color: context.appText),
          ),
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.podcasts_rounded, size: 14, color: Color(0xFFEF4444)),
          SizedBox(width: 5),
          Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFFEF4444),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessagesIcon extends StatefulWidget {
  const _MessagesIcon({required this.onMessages});

  final VoidCallback onMessages;

  @override
  State<_MessagesIcon> createState() => _MessagesIconState();
}

class _MessagesIconState extends State<_MessagesIcon> {
  late Future<List<MessageItem>> _unreadFuture;
  bool _didStart = false;
  int? _lastVersion;

  @override
  void initState() {
    super.initState();
    _unreadFuture = Future.value(const <MessageItem>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.watch(context);
    if (!_didStart || _lastVersion != controller.messageStateVersion) {
      final isLiveUpdate = _didStart;
      _didStart = true;
      _lastVersion = controller.messageStateVersion;
      _unreadFuture = controller.repositories.messages.fetchConversations(
        forceRefresh: isLiveUpdate,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MessageItem>>(
      future: _unreadFuture,
      builder: (context, snapshot) {
        final unreadCount = (snapshot.data ?? const <MessageItem>[])
            .fold<int>(
              0,
              (sum, item) =>
                  sum + (item.unreadCount > 0 ? item.unreadCount : 0),
            );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _CircleIconButton(
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: widget.onMessages,
              tooltip: 'الرسائل',
            ),
            if (unreadCount > 0)
              PositionedDirectional(
                top: 2,
                end: 2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: context.appSurface, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Bell icon with a live unread badge. Tapping it opens a sheet showing the
/// latest 4 notifications plus a button to view the full notifications page.
class _NotificationsIcon extends StatefulWidget {
  const _NotificationsIcon();

  @override
  State<_NotificationsIcon> createState() => _NotificationsIconState();
}

class _NotificationsIconState extends State<_NotificationsIcon> {
  late Future<List<NotificationItemModel>> _future;
  bool _didStart = false;
  int? _lastVersion;

  @override
  void initState() {
    super.initState();
    _future = Future.value(const <NotificationItemModel>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.watch(context);
    if (!_didStart || _lastVersion != controller.realtimeNotificationVersion) {
      final isLiveUpdate = _didStart;
      _didStart = true;
      _lastVersion = controller.realtimeNotificationVersion;
      _future = controller.repositories.notifications.fetchNotifications(
        forceRefresh: isLiveUpdate,
      );
    }
  }

  Future<void> _openSheet() async {
    final navigator = Navigator.of(context);
    final controller = AppScope.read(context);
    final surface = context.appSurface;
    // Use a fresh fetch so the sheet always shows the latest.
    final future = controller.repositories.notifications.fetchNotifications();
    final result = await showModalBottomSheet<Object?>(
      context: context,
      backgroundColor: surface,
      showDragHandle: true,
      // Size to content (and allow growth) so the sheet never clips its
      // children at the default half-screen cap.
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _NotificationsSheet(future: future),
    );
    if (!mounted) {
      return;
    }
    if (result == 'all') {
      navigator.push(
        MaterialPageRoute(
          builder: (routeContext) => Scaffold(
            body: NotificationsScreen(
              onMenu: () => Navigator.of(routeContext).maybePop(),
              onMessages: () => Navigator.of(routeContext).push(
                MaterialPageRoute(builder: (_) => const MessagesScreen()),
              ),
            ),
          ),
        ),
      );
    } else if (result is NotificationItemModel) {
      // Tapping a notification in the dropdown marks it read and routes to
      // its target, mirroring the full notifications screen.
      if (result.unread) {
        unawaited(
          controller.repositories.notifications.markRead(result.id),
        );
        controller.notifyNotificationStateChanged();
      }
      await openNotificationAction(context, result.actionUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<NotificationItemModel>>(
      future: _future,
      builder: (context, snapshot) {
        final unread = (snapshot.data ?? const <NotificationItemModel>[])
            .where((item) => item.unread)
            .length;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _CircleIconButton(
              icon: Icons.notifications_none_rounded,
              onPressed: _openSheet,
              tooltip: 'الإشعارات',
            ),
            if (unread > 0)
              PositionedDirectional(
                top: 2,
                end: 2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: context.appSurface, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet({required this.future});

  final Future<List<NotificationItemModel>> future;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'آخر الإشعارات',
                style: TextStyle(
                  color: context.appText,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<NotificationItemModel>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final items = (snapshot.data ?? const <NotificationItemModel>[])
                    .take(4)
                    .toList();
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    child: Text(
                      'لا توجد إشعارات بعد',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.appMuted),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final item in items)
                      _SheetNotificationTile(
                        item: item,
                        onTap: () => Navigator.of(context).pop(item),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop('all'),
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('عرض كل الإشعارات'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetNotificationTile extends StatelessWidget {
  const _SheetNotificationTile({required this.item, this.onTap});

  final NotificationItemModel item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: context.appSurfaceAlt.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appBorder.withValues(alpha: 0.6)),
        ),
        child: Row(
        children: [
          Icon(
            item.unread
                ? Icons.notifications_active_outlined
                : Icons.notifications_none,
            color: item.unread ? AppColors.blue : context.appMuted,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.appText,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                if (item.preview.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appMuted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          if (item.time.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(
              item.time,
              style: TextStyle(color: context.appMuted, fontSize: 11),
            ),
          ],
        ],
        ),
      ),
    );
  }
}
