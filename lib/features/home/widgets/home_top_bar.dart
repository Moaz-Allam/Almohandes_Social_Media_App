import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/layout_breakpoints.dart';
import '../../../models/message_item.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../state/app_scope.dart';

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
                      'بغداد',
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
            _CircleIconButton(
              icon: Icons.notifications_none_rounded,
              onPressed: () {},
              tooltip: 'الإشعارات',
            ),
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
      _didStart = true;
      _lastVersion = controller.messageStateVersion;
      _unreadFuture = controller.repositories.messages.fetchConversations();
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
