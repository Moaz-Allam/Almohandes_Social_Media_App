import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/notification_item_model.dart';
import '../../../shared/widgets/app_avatar.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.item});

  final NotificationItemModel item;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: item.unread ? AppColors.paleBlue : Colors.white,
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
                    Text(
                      item.time,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert, color: AppColors.muted),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.unread ? Colors.white : const Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE7E7E7)),
                  ),
                  child: Text(
                    item.preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14.5, height: 1.25),
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  '2,487 تفاعل · 275 تعليق',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
