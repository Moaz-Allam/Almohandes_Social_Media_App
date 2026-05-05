import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
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
      leading: Stack(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: AppAvatar(name: item.name, radius: 29, color: item.color),
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
          Text(item.time, style: const TextStyle(color: AppColors.muted)),
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
                color: Colors.black,
                fontWeight: item.unread ? FontWeight.w900 : FontWeight.w400,
              ),
            ),
          ),
          if (item.unread)
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsetsDirectional.only(start: 8),
              decoration: const BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '1',
                  style: TextStyle(
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
