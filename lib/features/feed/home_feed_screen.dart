import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
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
      headline: 'مهندس مدني · إشراف مواقع',
      time: 'قبل 16 ساعة',
      body:
          'نبحث عن مهندس موقع لمشروع سكني في بغداد. المطلوب خبرة في متابعة التنفيذ اليومي ورفع تقارير تقدم واضحة للفريق.',
      reactions: '77',
      comments: '52 تعليق',
      avatarColor: AppColors.darkBlue,
      showMedia: false,
    ),
    FeedPostModel(
      name: 'شيرين أمين',
      headline: 'مهندسة معمارية',
      time: 'قبل 17 ساعة',
      body:
          'انتهينا اليوم من مراجعة مخططات الواجهات لمجمع تجاري. التنسيق المبكر بين المعماري والمدني اختصر علينا الكثير من التعديلات.',
      reactions: '214',
      comments: '31 تعليق',
      avatarColor: AppColors.blue,
      showMedia: true,
    ),
    FeedPostModel(
      name: 'محمود عبد الله',
      headline: 'مدير مشروع · شركة الرافدين للبناء',
      time: 'قبل يوم',
      body:
          'فتحنا باب الانضمام لفريق تنفيذ مدرسة جديدة في البصرة. نحتاج فني كهرباء وسباك ومشرف سلامة ضمن فريق واحد.',
      reactions: '490',
      comments: '84 تعليق',
      avatarColor: AppColors.muted,
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
