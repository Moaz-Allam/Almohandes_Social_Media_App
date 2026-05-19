import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/message_item.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/search_pill.dart';
import '../../../state/app_scope.dart';
import '../../search/search_screen.dart';

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

  void _openSearch(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
  }

  @override
  Widget build(BuildContext context) {
    // Stateless wrt. AppController. Each interactive piece (avatar, unread
    // icon) subscribes only to the slice of state it actually needs, so
    // a notify on one (e.g. unread count) doesn't repaint the rest.
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: context.appSurface,
          border: Border(bottom: BorderSide(color: context.appBorder)),
        ),
        child: Row(
          children: [
            _TopBarAvatar(onMenu: onMenu),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _openSearch(context),
                borderRadius: BorderRadius.circular(4),
                child: SearchPill(hint: hint),
              ),
            ),
            const SizedBox(width: 10),
            _MessagesIcon(onMessages: onMessages),
          ],
        ),
      ),
    );
  }
}

class _TopBarAvatar extends StatelessWidget {
  const _TopBarAvatar({required this.onMenu});

  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    // Subscribe only here — the rest of the bar doesn't need to rebuild
    // when the profile updates.
    final profile = AppScope.watch(context).profile;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : 'المستخدم';
    final badge = profile?.role.isNotEmpty == true ? profile!.role : null;
    return GestureDetector(
      key: const ValueKey('home-menu-avatar'),
      onTap: onMenu,
      child: AppAvatar(
        name: name,
        radius: 20,
        color: AppColors.darkBlue,
        badge: badge,
        imageUrl: profile?.avatarUrl,
      ),
    );
  }
}

/// Holds the unread-conversations Future in state so the top bar doesn't
/// fire a new query on every keyboard / tab rebuild.
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
            IconButton(
              onPressed: widget.onMessages,
              icon: const Icon(
                Icons.chat_bubble,
                color: AppColors.muted,
              ),
              tooltip: 'الرسائل',
            ),
            if (unreadCount > 0)
              PositionedDirectional(
                top: 3,
                end: 2,
                child: _UnreadBadge(count: unreadCount),
              ),
          ],
        );
      },
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: context.appSurface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
