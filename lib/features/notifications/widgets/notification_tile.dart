import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/notification_item_model.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.item,
    required this.onMarkRead,
    required this.onDelete,
    this.onTap,
  });

  final NotificationItemModel item;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  /// Invoked when the body of the tile is tapped. Routes to the
  /// notification's target (post / reel / profile / chat) when set.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: item.unread ? context.appPaleBlue : context.appSurface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.unread)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 26, left: 8),
              decoration: const BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
              ),
            )
          else
            const SizedBox(width: 16),
          _NotificationTypeLogo(item: item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(fontSize: 15.5, height: 1.28),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(item.time, style: TextStyle(color: context.appMuted)),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.muted),
                      onSelected: (value) {
                        if (value == 'read') {
                          onMarkRead();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'read',
                          child: Text('تعليم كمقروء'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.unread ? context.appSurface : context.appSoft,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: context.appBorder),
                  ),
                  child: Text(
                    item.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14.5, height: 1.25),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.unread ? 'غير مقروء' : 'مقروء',
                  style: TextStyle(color: context.appMuted),
                ),
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTypeLogo extends StatelessWidget {
  const _NotificationTypeLogo({required this.item});

  final NotificationItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: .12),
        shape: BoxShape.circle,
        border: Border.all(color: item.color.withValues(alpha: .22)),
      ),
      child: Icon(_iconForType(item.type), color: item.color, size: 28),
    );
  }

  IconData _iconForType(String type) {
    final value = type.toLowerCase();
    if (value.contains('message') || value.contains('chat')) {
      return Icons.chat_bubble_outline;
    }
    if (value.contains('connection') || value.contains('connect')) {
      return Icons.person_add_alt_1;
    }
    if (value.contains('project') || value.contains('proposal')) {
      return Icons.assignment_turned_in_outlined;
    }
    if (value.contains('comment')) {
      return Icons.mode_comment_outlined;
    }
    if (value.contains('like') || value.contains('reaction')) {
      return Icons.thumb_up_alt_outlined;
    }
    if (value.contains('repost') || value.contains('share')) {
      return Icons.repeat;
    }
    if (value.contains('follow')) {
      return Icons.person_add_alt;
    }
    return Icons.notifications_none;
  }
}
