import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/story_item.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../state/app_scope.dart';
import '../../stories/story_viewer_screen.dart';

class StoriesStrip extends StatefulWidget {
  const StoriesStrip({super.key});

  @override
  State<StoriesStrip> createState() => _StoriesStripState();
}

class _StoriesStripState extends State<StoriesStrip> {
  late Future<List<StoryItem>> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _storiesFuture = Future.value(const <StoryItem>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _storiesFuture = AppScope.read(context).repositories.stories.fetchStories();
  }

  void _openStory(BuildContext context, List<StoryItem> stories, int index) {
    if (stories.isEmpty) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            StoryViewerScreen(stories: stories, initialIndex: index),
      ),
    );
  }

  Future<void> _createStory(BuildContext context) async {
    final controller = TextEditingController();
    final content = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('قصة جديدة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          textDirection: TextDirection.rtl,
          decoration: const InputDecoration(hintText: 'اكتب محتوى القصة'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('نشر'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!context.mounted || content == null || content.trim().isEmpty) {
      return;
    }
    await AppScope.read(context).repositories.stories.createTextStory(content);
    if (!mounted) {
      return;
    }
    setState(() {
      _storiesFuture = AppScope.read(
        context,
      ).repositories.stories.fetchStories(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: FutureBuilder<List<StoryItem>>(
        future: _storiesFuture,
        builder: (context, snapshot) {
          final stories = snapshot.data ?? const <StoryItem>[];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'القصص',
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 126,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: stories.length + 1,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _CreateStoryCard(
                        onTap: () => _createStory(context),
                      );
                    }
                    final story = stories[index - 1];
                    return _StoryCard(
                      cardKey: ValueKey('story-card-${story.id}'),
                      story: story,
                      onTap: () => _openStory(context, stories, index - 1),
                    );
                  },
                ),
              ),
              if (stories.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'لا توجد قصص بعد',
                    style: TextStyle(color: context.appMuted, fontSize: 13),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CreateStoryCard extends StatelessWidget {
  const _CreateStoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 82,
      height: 126,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.appPaleBlue,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.blue, width: 2),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
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
          backgroundColor: context.appSurface,
          padding: EdgeInsets.zero,
          side: BorderSide(
            color: story.isNew ? AppColors.blue : context.appBorder,
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
                style: TextStyle(
                  color: context.appText,
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
