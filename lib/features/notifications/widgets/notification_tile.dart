import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/notification_item_model.dart';
import '../../../shared/widgets/app_avatar.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.item,
    required this.onMarkRead,
    required this.onDelete,
  });

  final NotificationItemModel item;
  final VoidCallback onMarkRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: item.unread ? context.appPaleBlue : context.appSurface,
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
          AppAvatar(name: item.title, radius: 30, color: item.color),
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
    );
  }
}
