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
    final profile = AppScope.watch(context).profile;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : 'المستخدم';
    final badge = profile?.role.isNotEmpty == true ? profile!.role : null;

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
            GestureDetector(
              key: const ValueKey('home-menu-avatar'),
              onTap: onMenu,
              child: AppAvatar(
                name: name,
                radius: 20,
                color: AppColors.darkBlue,
                badge: badge,
                imageUrl: profile?.avatarUrl,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _openSearch(context),
                borderRadius: BorderRadius.circular(4),
                child: SearchPill(hint: hint),
              ),
            ),
            const SizedBox(width: 10),
            FutureBuilder<List<MessageItem>>(
              future: AppScope.read(
                context,
              ).repositories.messages.fetchConversations(),
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
                      onPressed: onMessages,
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
            ),
          ],
        ),
      ),
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
