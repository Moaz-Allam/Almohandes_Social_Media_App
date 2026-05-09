import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/message_item.dart';
import '../../../shared/widgets/app_avatar.dart';

class MessageTile extends StatelessWidget {
  const MessageTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onProfileTap,
  });

  final MessageItem item;
  final VoidCallback onTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      tileColor: item.unread
          ? context.appPaleBlue.withValues(alpha: .35)
          : null,
      leading: Stack(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: AppAvatar(
              name: item.name,
              radius: 29,
              color: item.color,
              imageUrl: item.avatarUrl,
            ),
          ),
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(item.time, style: TextStyle(color: context.appMuted)),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              item.preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.appText,
                fontWeight: item.unread ? FontWeight.w900 : FontWeight.w400,
              ),
            ),
          ),
          if (item.unread)
            Container(
              constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              margin: const EdgeInsetsDirectional.only(start: 8),
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Center(
                child: Text(
                  item.unreadCount > 99 ? '99+' : '${item.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
