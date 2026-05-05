import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../models/story_item.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../stories/story_viewer_screen.dart';

class StoriesStrip extends StatelessWidget {
  const StoriesStrip({super.key});

  static const _stories = [
    StoryItem(name: 'ريم حسن', color: AppColors.blue, isNew: true),
    StoryItem(name: 'أحمد منصور', color: AppColors.darkBlue, isNew: true),
    StoryItem(name: 'شيرين أمين', color: AppColors.muted),
    StoryItem(name: 'مريانا جونز', color: AppColors.black, isNew: true),
    StoryItem(name: 'مازن محمود', color: AppColors.blue),
  ];

  void _openStory(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            StoryViewerScreen(stories: _stories, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _openStory(context, 0),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'القصص',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 126,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _stories.length + 1,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const _CreateStoryCard();
                }
                return _StoryCard(
                  cardKey: ValueKey('story-card-${index - 1}'),
                  story: _stories[index - 1],
                  onTap: () => _openStory(context, index - 1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateStoryCard extends StatelessWidget {
  const _CreateStoryCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 126,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.paleBlue,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blue, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'قصة جديدة',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.cardKey,
    required this.story,
    required this.onTap,
  });

  final Key cardKey;
  final StoryItem story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 126,
      child: OutlinedButton(
        key: cardKey,
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: story.isNew ? AppColors.blue : AppColors.border,
            width: story.isNew ? 2 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Column(
            children: [
              AppAvatar(name: story.name, radius: 27, color: story.color),
              const Spacer(),
              Text(
                story.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
