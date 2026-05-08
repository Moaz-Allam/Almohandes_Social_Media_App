import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/story_item.dart';
import '../../../shared/widgets/media_preview.dart';
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

  @override
  void initState() {
    super.initState();
    _storiesFuture = Future.value(const <StoryItem>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartLoading) {
      return;
    }
    _didStartLoading = true;
    _storiesFuture = AppScope.read(context).repositories.stories.fetchStories();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
      return;
    }
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نشر القصة')));
    setState(() {
      _storiesFuture = repositories.stories.fetchStories(forceRefresh: true);
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
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData;
          final stories = snapshot.data ?? const <StoryItem>[];
          final groups = _storyGroups(stories);
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
                child: isLoading
                    ? const _StoriesSkeletonList()
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: groups.length + 1,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _CreateStoryCard(
                              onTap: () => _createStory(context),
                            );
                          }
                          final group = groups[index - 1];
                          return _StoryCard(
                            cardKey: ValueKey('story-card-${group.id}'),
                            group: group,
                            seen: _seenStoryGroups.contains(group.id),
                            onTap: () => _openStory(context, group, 0),
                          );
                        },
                      ),
              ),
              if (!isLoading && stories.isEmpty)
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(bool video) async {
    final picker = ImagePicker();
    final picked = video
        ? await picker.pickVideo(source: ImageSource.gallery)
        : await picker.pickImage(
            source: ImageSource.gallery,
            maxWidth: 1200,
            imageQuality: 82,
          );
    if (picked == null || !mounted) {
      return;
    }
    final bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }
    final mimeType = picked.mimeType ?? (video ? 'video/mp4' : 'image/jpeg');
    setState(() {
      _mediaUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
      _mediaType = video ? 'video' : 'image';
    });
  }

  void _publish() {
    if (_mediaUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر صورة أو فيديو للقصة أولا')),
      );
      return;
    }
    Navigator.of(context).pop(
      _StoryDraft(
        content: _controller.text.trim(),
        mediaUrl: _mediaUrl,
        mediaType: _mediaType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('قصة جديدة'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                minLines: 2,
                maxLines: 4,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  hintText: 'اكتب النص الذي سيظهر أسفل الصورة/الفيديو',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickMedia(false),
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('صورة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickMedia(true),
                      icon: const Icon(Icons.videocam_outlined),
                      label: const Text('فيديو'),
                    ),
                  ),
                ],
              ),
              if (_mediaUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: .72,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MediaPreview(
                          mediaUrl: _mediaUrl,
                          mediaType: _mediaType,
                          fallbackLabel: _mediaType == 'video'
                              ? 'فيديو'
                              : 'صورة',
                        ),
                        if (_controller.text.trim().isNotEmpty)
                          PositionedDirectional(
                            start: 10,
                            end: 10,
                            bottom: 10,
                            child: _StoryTextOverlay(
                              text: _controller.text.trim(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _publish, child: const Text('نشر')),
      ],
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
    required this.group,
    required this.seen,
    required this.onTap,
  });

  final Key cardKey;
  final _StoryGroup group;
  final bool seen;
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
          side: seen
              ? BorderSide.none
              : const BorderSide(color: AppColors.blue, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: _StoryPreview(group: group),
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

class _StoryPreview extends StatelessWidget {
  const _StoryPreview({required this.group});

  final _StoryGroup group;

  @override
  Widget build(BuildContext context) {
    final story = group.preview;
    if (story.hasVisualMedia) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            MediaPreview(
              mediaUrl: story.mediaUrl,
              mediaType: story.mediaType,
              fallbackLabel: story.isVideo ? 'فيديو' : 'صورة',
            ),
            if (story.isVideo)
              const Center(
                child: Icon(Icons.play_circle, color: Colors.white, size: 28),
              ),
          ],
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: story.color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: _StoryAvatarFill(
          imageUrl: story.avatarUrl,
          color: AppColors.darkBlue,
        ),
      ),
    );
  }
}

class _StoryAvatarFill extends StatelessWidget {
  const _StoryAvatarFill({required this.imageUrl, required this.color});

  final String? imageUrl;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';
    final bytes = _bytesFromDataUrl(url);
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    if (url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return ColoredBox(
      color: color,
      child: const Center(
        child: Icon(Icons.person, color: Colors.white, size: 30),
      ),
    );
  }

  Uint8List? _bytesFromDataUrl(String value) {
    if (!value.startsWith('data:')) {
      return null;
    }
    final comma = value.indexOf(',');
    if (comma == -1) {
      return null;
    }
    try {
      return base64Decode(value.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }
}

class _StoriesSkeletonList extends StatelessWidget {
  const _StoriesSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(width: 10),
      itemBuilder: (context, index) => SizedBox(
        width: 82,
        height: 126,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.appSurfaceAlt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryTextOverlay extends StatelessWidget {
  const _StoryTextOverlay({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .58),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1.2,
        ),
      ),
    );
  }
}
