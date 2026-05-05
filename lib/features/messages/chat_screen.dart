import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/message_item.dart';
import '../../shared/widgets/app_avatar.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.contact});

  final MessageItem contact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 62,
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
                  AppAvatar(
                    name: contact.name,
                    radius: 22,
                    color: contact.color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'نشط الآن',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'المزيد',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                children: [
                  _MessageBubble(
                    text: contact.preview.replaceFirst('أنت: ', ''),
                    incoming: true,
                  ),
                  const _MessageBubble(
                    text: 'أكيد، أراجع التفاصيل الآن وأرسل لك النسخة النهائية.',
                    incoming: false,
                  ),
                  const _MessageBubble(
                    text: 'ممتاز، شكرا لك. أحتاجها قبل نهاية اليوم.',
                    incoming: true,
                  ),
                  const _MessageBubble(
                    text: 'تمام، ستكون جاهزة خلال ساعة.',
                    incoming: false,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.blue,
                    ),
                    tooltip: 'إضافة',
                  ),
                  Expanded(
                    child: TextField(
                      minLines: 1,
                      maxLines: 3,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        filled: true,
                        fillColor: AppColors.soft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.blue),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.send, color: AppColors.blue),
                    tooltip: 'إرسال',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.incoming});

  final String text;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: incoming ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 292),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: incoming ? AppColors.soft : AppColors.paleBlue,
          borderRadius: BorderRadius.circular(16).copyWith(
            topRight: incoming ? const Radius.circular(4) : null,
            topLeft: incoming ? null : const Radius.circular(4),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15, height: 1.35)),
      ),
    );
  }
}
