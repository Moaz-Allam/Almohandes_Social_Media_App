import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'app_avatar.dart';

Future<void> showLinkedCommentsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const LinkedCommentsSheet(),
  );
}

class LinkedCommentsSheet extends StatelessWidget {
  const LinkedCommentsSheet({super.key});

  static const _comments = [
    _Comment(
      name: 'فاطمة شاهين',
      role: 'مصممة تجربة مستخدم',
      time: 'قبل يوم',
      text: 'لفتتني الفكرة جدا، خصوصا ربط التجربة بقياس واضح قبل الإطلاق.',
      likes: '1',
      color: Color(0xFF2C5C7A),
    ),
    _Comment(
      name: 'معتز سند',
      role: 'مدير منتج',
      time: 'قبل 15 ساعة',
      text:
          'أتفق معك. القرارات المبنية على بحث المستخدم توفر وقتا كبيرا على فرق المنتج والهندسة، وتقلل إعادة العمل بعد الإطلاق.',
      likes: '4',
      color: Color(0xFF5D5D5D),
    ),
    _Comment(
      name: 'مي عبد الرحمن',
      role: 'محللة بيانات',
      time: 'قبل 7 ساعات',
      text: 'سيكون مفيدا لو شاركتوا قالب الأسئلة المستخدم في المقابلات.',
      likes: '2',
      color: Color(0xFFD16A6A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .78,
      minChildSize: .45,
      maxChildSize: .96,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 58,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: Row(
                  children: [
                    const Text(
                      'الأكثر صلة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down, size: 22),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    return _CommentTile(comment: _comments[index]);
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    const AppAvatar(
                      name: 'ريم حسن',
                      radius: 20,
                      color: Color(0xFF9151A8),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'أضف تعليقا...',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 11,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(26),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(26),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final _Comment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(name: comment.name, radius: 24, color: comment.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      comment.time,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert, color: AppColors.muted),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                Text(
                  comment.role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                Text(
                  comment.text,
                  style: const TextStyle(fontSize: 15.5, height: 1.35),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.thumb_up_alt_outlined, size: 20),
                    const SizedBox(width: 4),
                    Text(comment.likes),
                    const SizedBox(width: 18),
                    const Icon(Icons.mode_comment_outlined, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Comment {
  const _Comment({
    required this.name,
    required this.role,
    required this.time,
    required this.text,
    required this.likes,
    required this.color,
  });

  final String name;
  final String role;
  final String time;
  final String text;
  final String likes;
  final Color color;
}
