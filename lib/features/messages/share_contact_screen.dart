import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/feed_post_model.dart';
import '../../models/message_item.dart';
import '../../shared/widgets/app_avatar.dart';
import 'chat_screen.dart';

class ShareContactScreen extends StatelessWidget {
  const ShareContactScreen({super.key, required this.post});

  final FeedPostModel post;

  static const _contacts = [
    MessageItem(
      name: 'أندرو مارتن',
      preview: 'هل يمكنك إرسال الفاتورة؟',
      time: '10:07 ص',
      unread: true,
      color: Color(0xFF5D8E64),
    ),
    MessageItem(
      name: 'جيمي لي',
      preview: 'أنت: تمام، وصلني!',
      time: 'الخميس',
      unread: false,
      color: Color(0xFF705CB9),
    ),
    MessageItem(
      name: 'سارة خليل',
      preview: 'أنت: أظن أن هذا متعلق بضمان الجودة',
      time: 'الأربعاء',
      unread: false,
      color: Color(0xFFD66B7B),
    ),
    MessageItem(
      name: 'وليد إلياس',
      preview: 'أنت: راجعت التقرير المناسب',
      time: 'الاثنين',
      unread: false,
      color: Color(0xFF4C8D72),
    ),
  ];

  void _sendToContact(BuildContext context, MessageItem contact) {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatScreen(contact: contact)),
    );
    messenger.showSnackBar(
      SnackBar(
        content: Text('تم إرسال منشور ${post.name} إلى ${contact.name}'),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'رجوع',
                  ),
                  const Expanded(
                    child: Text(
                      'إرسال إلى',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.soft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.article_outlined, color: AppColors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'مشاركة منشور ${post.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _contacts.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final contact = _contacts[index];
                  return ListTile(
                    leading: AppAvatar(
                      name: contact.name,
                      radius: 27,
                      color: contact.color,
                    ),
                    title: Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    subtitle: Text(
                      contact.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: FilledButton(
                      onPressed: () => _sendToContact(context, contact),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('إرسال'),
                    ),
                    onTap: () => _sendToContact(context, contact),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
