import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/notification_item_model.dart';
import '../home/widgets/home_top_bar.dart';
import 'widgets/notification_tile.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({
    super.key,
    required this.onMenu,
    required this.onMessages,
  });

  final VoidCallback onMenu;
  final VoidCallback onMessages;

  static const _items = [
    NotificationItemModel(
      title: 'ناتاليا شوستاك و 2,486 آخرون تفاعلوا مع منشورك',
      preview: 'هذه أخبار رائعة، أتطلع إلى نوفمبر ...',
      time: 'قبل دقيقة',
      unread: true,
      color: Color(0xFFD7434E),
    ),
    NotificationItemModel(
      title: 'سامسون كينيدي و 2,486 آخرون تفاعلوا مع منشورك',
      preview: 'في نوفمبر نطلق برنامج تدريب لمصممي UI/UX ...',
      time: 'قبل 10 دقائق',
      unread: true,
      color: Color(0xFF5D8E64),
    ),
    NotificationItemModel(
      title: 'أندريا بيكر علقت على منشورك',
      preview: 'هل يمكن مشاركة رابط التسجيل؟',
      time: 'قبل 56 دقيقة',
      unread: false,
      color: Color(0xFF7AA9CB),
    ),
    NotificationItemModel(
      title: 'شركة BaytPay نشرت وظيفة تناسب مهاراتك',
      preview: 'Product Designer · عمل هجين · القاهرة',
      time: 'قبل ساعتين',
      unread: false,
      color: Color(0xFF2C78A8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeTopBar(onMenu: onMenu, onMessages: onMessages),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: _items.length + 1,
            itemBuilder: (context, index) {
              if (index == _items.length) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(72, 12, 72, 24),
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text('عرض الإشعارات التي فاتتك'),
                  ),
                );
              }
              return NotificationTile(item: _items[index]);
            },
          ),
        ),
      ],
    );
  }
}
