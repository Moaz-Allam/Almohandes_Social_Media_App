import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/storage/media_upload_service.dart';
import '../../../models/story_item.dart';
import '../../../shared/widgets/app_snack.dart';
import '../../../shared/widgets/cached_image.dart';
import '../../../state/app_scope.dart';
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

  Future<void> _createStory(BuildContext context) async {
    final draft = await showDialog<_StoryDraft>(
      context: context,
      builder: (_) => const _StoryComposerDialog(),
    );
    if (!context.mounted || draft == null) {
      return;
    }
    final repositories = AppScope.read(context).repositories;
    try {
      await repositories.stories.createStory(
        content: draft.content,
        mediaUrl: draft.mediaUrl,
        mediaType: draft.mediaType,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      AppSnack.error(context, error, fallback: 'تعذر نشر القصة الآن');
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نشر القصة')));
    AppScope.read(context).notifyStoriesChanged();
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
                      seen: _seenStoryGroups.contains(group.id),
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
}

final class _StoryDraft {
  const _StoryDraft({
    required this.content,
    required this.mediaUrl,
    required this.mediaType,
  });
  final String content;
  final String mediaUrl;
  final String mediaType;
}

class _StoryComposerDialog extends StatefulWidget {
  const _StoryComposerDialog();
  @override
  State<_StoryComposerDialog> createState() => _StoryComposerDialogState();
}

class _StoryComposerDialogState extends State<_StoryComposerDialog> {
  final _controller = TextEditingController();
  String _mediaUrl = '';
  String _mediaType = 'image';
  bool _isUploading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(bool video) async {
    if (_isUploading) return;
    final XFile? picked;
    final Uint8List bytes;
    try {
      final picker = ImagePicker();
      picked = video
          ? await picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(seconds: 30))
          : await picker.pickImage(source: ImageSource.gallery, maxWidth: 1080, imageQuality: 60);
      if (picked == null) return;
      bytes = await picked.readAsBytes();
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(context, error, fallback: 'تعذر اختيار القصة الآن');
      return;
    }
    if (!mounted) return;
    setState(() => _isUploading = true);
    final mimeType = picked.mimeType ?? (video ? 'video/mp4' : 'image/jpeg');
    final media = AppScope.read(context).repositories.media;
    try {
      final url = await media.uploadBytes(
        bucket: video ? MediaBucket.reels : MediaBucket.stories,
        bytes: bytes,
        fileName: picked.name,
        mimeType: mimeType,
      );
      if (!mounted) return;
      setState(() {
        _mediaUrl = url;
        _mediaType = video ? 'video' : 'image';
      });
    } catch (error) {
      if (!mounted) return;
      AppSnack.error(context, error, fallback: 'تعذر رفع القصة الآن');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('قصة جديدة'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'اكتب النص للقصة'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => _pickMedia(false), child: const Text('صورة'))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton(onPressed: () => _pickMedia(true), child: const Text('فيديو'))),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(context, _StoryDraft(content: _controller.text, mediaUrl: _mediaUrl, mediaType: _mediaType)), child: const Text('نشر')),
      ],
    );
  }
}
