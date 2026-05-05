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
      color: AppColors.blue,
    ),
    NotificationItemModel(
      title: 'سامسون كينيدي و 2,486 آخرون تفاعلوا مع منشورك',
      preview: 'في نوفمبر نطلق برنامج تدريب لمصممي UI/UX ...',
      time: 'قبل 10 دقائق',
      unread: true,
      color: AppColors.darkBlue,
    ),
    NotificationItemModel(
      title: 'أندريا بيكر علقت على منشورك',
      preview: 'هل يمكن مشاركة رابط التسجيل؟',
      time: 'قبل 56 دقيقة',
      unread: false,
      color: AppColors.muted,
    ),
    NotificationItemModel(
      title: 'شركة BaytPay نشرت مشروعا يناسب مهاراتك',
      preview: 'Product Designer · مشروع هجين · القاهرة',
      time: 'قبل ساعتين',
      unread: false,
      color: AppColors.black,
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
