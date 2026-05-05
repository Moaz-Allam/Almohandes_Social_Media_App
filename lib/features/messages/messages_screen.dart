import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/message_item.dart';
import '../profile/profile_screen.dart';
import 'chat_screen.dart';
import 'widgets/message_tile.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const _contacts = [
    MessageItem(
      name: 'أندرو مارتن',
      preview: 'هل يمكنك إرسال الفاتورة؟',
      time: '10:07 ص',
      unread: true,
      color: AppColors.blue,
    ),
    MessageItem(
      name: 'جيمي لي',
      preview: 'أنت: تمام، وصلني!',
      time: 'الخميس',
      unread: false,
      color: AppColors.darkBlue,
    ),
    MessageItem(
      name: 'سارة خليل',
      preview: 'أنت: أظن أن هذا متعلق بضمان الجودة',
      time: 'الأربعاء',
      unread: false,
      color: AppColors.muted,
    ),
    MessageItem(
      name: 'وليد إلياس',
      preview: 'أنت: راجعت التقرير المناسب',
      time: 'الاثنين',
      unread: false,
      color: AppColors.black,
    ),
    MessageItem(
      name: 'مريم آدمز',
      preview: 'InMail · أهلا، الاجتماع مجدول...',
      time: 'الأحد',
      unread: false,
      color: AppColors.blue,
    ),
    MessageItem(
      name: 'جينيفر هيلتون',
      preview: 'هكذا يعمل التعاون على المهندس :)',
      time: 'الجمعة',
      unread: false,
      color: AppColors.darkBlue,
    ),
    MessageItem(
      name: 'نيل أبو جاه',
      preview: 'أنت: تمام، وصلني!',
      time: 'الخميس',
      unread: false,
      color: AppColors.muted,
    ),
    MessageItem(
      name: 'جيمس هندرسون',
      preview: '👍',
      time: '9 نوفمبر',
      unread: false,
      color: AppColors.black,
    ),
  ];

  void _openChat(BuildContext context, MessageItem contact) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatScreen(contact: contact)));
  }

  void _openProfile(BuildContext context, MessageItem contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          name: contact.name,
          headline: contact.preview.replaceFirst('أنت: ', ''),
          color: contact.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: context.appSurface,
                border: Border(bottom: BorderSide(color: context.appBorder)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'رجوع',
                  ),
                  const SizedBox(width: 2),
                  const Expanded(
                    child: Text(
                      'الرسائل',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'المزيد',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'رسالة جديدة',
                  ),
                ],
              ),
            ),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: context.appSurface,
                border: Border(bottom: BorderSide(color: context.appBorder)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: context.appMuted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'بحث في الرسائل',
                      style: TextStyle(color: context.appMuted),
                    ),
                  ),
                  Icon(Icons.tune, color: context.appMuted, size: 20),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _contacts.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, indent: 78, color: context.appBorder),
                itemBuilder: (context, index) => MessageTile(
                  item: _contacts[index],
                  onTap: () => _openChat(context, _contacts[index]),
                  onProfileTap: () => _openProfile(context, _contacts[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
