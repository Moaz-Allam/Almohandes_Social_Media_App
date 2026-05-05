import 'package:flutter/material.dart';

import '../../models/feed_post_model.dart';
import '../home/widgets/home_top_bar.dart';
import 'widgets/feed_post_card.dart';
import 'widgets/stories_strip.dart';

class HomeFeedScreen extends StatelessWidget {
  const HomeFeedScreen({
    super.key,
    required this.onMenu,
    required this.onMessages,
  });

  final VoidCallback onMenu;
  final VoidCallback onMessages;

  static const _posts = [
    FeedPostModel(
      name: 'أحمد منصور',
      headline: 'مطور Flutter في Nile Apps',
      time: 'قبل 16 ساعة',
      body:
          'أبحث عن فرصة جديدة في تطوير تطبيقات الموبايل، وسأكون ممتنا لأي ترشيح أو نصيحة أو تواصل مع فرق تبحث عن مطور يهتم بجودة التجربة.',
      reactions: '77',
      comments: '52 تعليق',
      avatarColor: Color(0xFFC9B3A4),
      showMedia: false,
    ),
    FeedPostModel(
      name: 'شيرين أمين',
      headline: 'مصممة UI/UX',
      time: 'قبل 17 ساعة',
      body:
          'انتهينا اليوم من اختبار قابلية استخدام لتجربة الدفع الجديدة. أجمل ما في البحث أنه يغير افتراضاتنا بسرعة.',
      reactions: '214',
      comments: '31 تعليق',
      avatarColor: Color(0xFF5E7893),
      showMedia: true,
    ),
    FeedPostModel(
      name: 'محمود عبد الله',
      headline: 'مدير منتج في FinHub',
      time: 'قبل يوم',
      body:
          'نفتح باب التدريب الصيفي لفريق المنتج. نبحث عن أشخاص فضوليين يحبون حل المشكلات وكتابة فرضيات واضحة.',
      reactions: '490',
      comments: '84 تعليق',
      avatarColor: Color(0xFFB7694F),
      showMedia: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeTopBar(onMenu: onMenu, onMessages: onMessages),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const StoriesStrip(),
              for (final post in _posts) FeedPostCard(post: post),
            ],
          ),
        ),
      ],
    );
  }
}
