import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/story_item.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../state/app_scope.dart';
import '../../stories/story_create_screen.dart';
import '../../stories/story_viewer_screen.dart';

class StoriesStrip extends StatefulWidget {
  const StoriesStrip({super.key});

  @override
  State<StoriesStrip> createState() => _StoriesStripState();
}

class _StoriesStripState extends State<StoriesStrip> {
  late Future<List<StoryItem>> _storiesFuture;
  final Set<String> _seenStoryGroups = {};
  bool _didStartLoading = false;
  int _lastStoriesVersion = 0;

  @override
  void initState() {
    super.initState();
    _storiesFuture = Future.value(const <StoryItem>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.watch(context);
    final shouldRefresh = !_didStartLoading ||
        controller.storiesVersion != _lastStoriesVersion;
    if (!shouldRefresh) {
      return;
    }
    _didStartLoading = true;
    _lastStoriesVersion = controller.storiesVersion;
    _storiesFuture = controller.repositories.stories.fetchStories(
      forceRefresh: true,
    );
  }

  void _openStory(BuildContext context, _StoryGroup group, int index) {
    final stories = group.stories;
    if (stories.isEmpty) {
      return;
    }
    setState(() => _seenStoryGroups.add(group.id));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            StoryViewerScreen(stories: stories, initialIndex: index),
      ),
    );
  }

  void _createStory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StoryCreateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(bottom: BorderSide(color: context.appBorder.withValues(alpha: 0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // RTL start (visual right): accent bar first, then title.
                Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        context.appPrimary,
                        context.appPrimary.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'القصص',
                  style: TextStyle(
                    color: context.appText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: FutureBuilder<List<StoryItem>>(
              future: _storiesFuture,
              builder: (context, snapshot) {
                final stories = snapshot.data ?? const <StoryItem>[];
                final groups = _storyGroups(stories);

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: groups.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _CreateStoryCard(onTap: () => _createStory(context));
                    }
                    final group = groups[index - 1];
                    return _StoryCard(
                      group: group,
                      seen: group.seen || _seenStoryGroups.contains(group.id),
                      onTap: () => _openStory(context, group, 0),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_StoryGroup> _storyGroups(List<StoryItem> stories) {
    final byProfile = <String, List<StoryItem>>{};
    for (final story in stories) {
      final key = story.profileId.isNotEmpty ? story.profileId : story.name;
      byProfile.putIfAbsent(key, () => []).add(story);
    }
    return [
      for (final entry in byProfile.entries)
        _StoryGroup(id: entry.key, stories: entry.value),
    ];
  }
}

class _CreateStoryCard extends StatelessWidget {
  const _CreateStoryCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          color: context.appSurfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.appBorder.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.appPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_rounded,
                color: context.appPrimary,
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'قصتك',
              style: TextStyle(
                color: context.appText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
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
    required this.group,
    required this.seen,
    required this.onTap,
  });

  final _StoryGroup group;
  final bool seen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final story = group.preview;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: seen
              ? null
              : LinearGradient(
                  colors: [
                    context.appPrimary,
                    context.appPrimary.withValues(alpha: 0.5),
                    const Color(0xFFF43F5E),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          border: seen
              ? Border.all(
                  color: context.appBorder.withValues(alpha: 0.6),
                  width: 2,
                )
              : null,
        ),
        padding: seen ? EdgeInsets.zero : const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedImage(
                url: story.isVideo ? '' : story.mediaUrl,
                fallback: Container(
                  color: story.color.withValues(alpha: 0.3),
                  child: Center(child: Text(story.name[0], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                ),
              ),
              // Name overlay
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Text(
                  story.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),
              // Avatar mini overlay
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                  ),
                  child: ClipOval(
                    child: CachedImage(url: story.avatarUrl),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StoryGroup {
  const _StoryGroup({required this.id, required this.stories});
  final String id;
  final List<StoryItem> stories;
  StoryItem get preview => stories.first;

  /// A group reads as "seen" only once every story in it has been viewed
  /// (matches Instagram: the ring stays bright until you finish the set).
  bool get seen => stories.isNotEmpty && stories.every((s) => s.seen);
}

