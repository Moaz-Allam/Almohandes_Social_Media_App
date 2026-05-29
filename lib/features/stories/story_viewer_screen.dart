import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/story_item.dart';
import '../../models/story_viewer.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/media_preview.dart';
import '../../state/app_scope.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.stories,
    required this.initialIndex,
  });

  final List<StoryItem> stories;
  final int initialIndex;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with TickerProviderStateMixin {
  static const _storyDuration = Duration(seconds: 6);
  static const _burstDuration = Duration(milliseconds: 1100);
  static const _reactionEmojis = ['❤️', '😂', '😮', '😢', '🔥', '👏'];

  late final PageController _controller;
  late final AnimationController _progress;
  late final AnimationController _burst;
  late int _index;
  bool _isHeld = false;
  String? _burstEmoji;
  String? _myProfileId;
  // Stories whose view we've already recorded this session, so paging back and
  // forth doesn't fire the RPC repeatedly.
  final Set<String> _recordedViews = {};

  @override
  void initState() {
    super.initState();
    _index = widget.stories.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.stories.length - 1);
    _controller = PageController(initialPage: _index);
    _progress = AnimationController(vsync: this, duration: _storyDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goNext();
        }
      })
      ..forward();
    _burst = AnimationController(vsync: this, duration: _burstDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _burstEmoji = null);
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _myProfileId ??= AppScope.read(context).profile?.id;
    // Record the first story as viewed once we have a profile context.
    _markViewed(_index);
  }

  @override
  void dispose() {
    _progress.dispose();
    _burst.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Records that the viewer opened the story at [index] (skipping the
  /// viewer's own stories so a creator never appears in their own audience).
  void _markViewed(int index) {
    if (index < 0 || index >= widget.stories.length) {
      return;
    }
    final story = widget.stories[index];
    if (story.id.isEmpty) {
      return;
    }
    if (story.profileId.isNotEmpty && story.profileId == _myProfileId) {
      return;
    }
    if (!_recordedViews.add(story.id)) {
      return;
    }
    AppScope.read(context).repositories.stories.markStoryViewed(story.id);
  }

  bool _isMine(StoryItem story) =>
      story.profileId.isNotEmpty && story.profileId == _myProfileId;

  Future<void> _openViewers(StoryItem story) async {
    _pauseProgress();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StoryViewersSheet(story: story),
    );
    if (mounted) {
      _resumeProgress();
    }
  }

  void _restartProgress() {
    _progress.forward(from: 0);
  }

  void _pauseProgress() {
    if (_isHeld) {
      return;
    }
    _isHeld = true;
    _progress.stop(canceled: false);
  }

  void _resumeProgress() {
    if (!_isHeld) {
      return;
    }
    _isHeld = false;
    if (_progress.status != AnimationStatus.completed) {
      _progress.forward();
    }
  }

  void _goNext() {
    if (_index >= widget.stories.length - 1) {
      Navigator.of(context).maybePop();
      return;
    }
    _controller.animateToPage(
      _index + 1,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _goPrevious() {
    if (_index == 0) {
      _restartProgress();
      return;
    }
    _controller.animateToPage(
      _index - 1,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _sendReaction(String emoji, StoryItem story) {
    if (story.id.isEmpty) {
      return;
    }
    // Trigger the big centre burst immediately so the tap feels
    // responsive even on slow networks. The actual upsert runs in the
    // background and any error is recovered silently — losing a story
    // reaction isn't worth surfacing a snackbar.
    setState(() => _burstEmoji = emoji);
    _burst.forward(from: 0);
    AppScope.read(context).repositories.stories.reactToStory(
          storyId: story.id,
          emoji: emoji,
        );
  }

  void _handleDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -120) {
      _goPrevious();
    } else if (velocity > 120) {
      _goNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stories.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final currentStory = widget.stories[_index];

    return Scaffold(
      key: const ValueKey('story-viewer'),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: _handleDrag,
            // Long-press anywhere pauses the story; lifting resumes it.
            onLongPressStart: (_) => _pauseProgress(),
            onLongPressEnd: (_) => _resumeProgress(),
            onLongPressCancel: _resumeProgress,
            onTapUp: (details) {
              final width = context.size?.width ??
                  MediaQuery.sizeOf(context).width;
              if (details.localPosition.dx < width / 2) {
                _goNext();
              } else {
                _goPrevious();
              }
            },
            // Lock story content to a phone-shaped viewport so it doesn't
            // stretch across a desktop browser. Outside this column the
            // background stays solid black, like Instagram on the web.
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: MediaQuery.sizeOf(context).height,
              ),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.stories.length,
                onPageChanged: (value) {
                  setState(() {
                    _index = value;
                    _burstEmoji = null;
                  });
                  _burst.stop();
                  _restartProgress();
                  _markViewed(value);
                },
                itemBuilder: (context, index) {
                  final story = widget.stories[index];
                  return _StoryImage(story: story, index: index);
                },
              ),
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) {
                        return Row(
                          children: [
                            for (var i = 0; i < widget.stories.length; i++)
                              Expanded(
                                child: _StoryProgressSegment(
                                  value: i < _index
                                      ? 1
                                      : i == _index
                                      ? _progress.value
                                      : 0,
                                  isActive: i <= _index,
                                  hasStartMargin: i != 0,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.close, color: Colors.white),
                          tooltip: 'إغلاق',
                        ),
                        const Spacer(),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: .55),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: .35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              currentStory.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        AppAvatar(
                          name: currentStory.name,
                          radius: 22,
                          color: currentStory.color,
                          imageUrl: currentStory.avatarUrl,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 16,
                // Your own story shows "who viewed it"; everyone else's shows
                // the emoji reaction bar.
                child: _isMine(currentStory)
                    ? _StoryViewersButton(
                        count: currentStory.viewsCount,
                        onTap: () => _openViewers(currentStory),
                      )
                    : _StoryReactionBar(
                        emojis: _reactionEmojis,
                        onTap: (emoji) => _sendReaction(emoji, currentStory),
                      ),
              ),
              if (_burstEmoji != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _StoryReactionBurst(
                      controller: _burst,
                      emoji: _burstEmoji!,
                    ),
                  ),
                ),
            ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryReactionBar extends StatelessWidget {
  const _StoryReactionBar({
    required this.emojis,
    required this.onTap,
  });

  final List<String> emojis;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .45),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: .14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final emoji in emojis)
              _ReactionButton(
                emoji: emoji,
                onTap: () => onTap(emoji),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  const _ReactionButton({required this.emoji, required this.onTap});

  final String emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 26),
        ),
      ),
    );
  }
}

/// Plays a one-shot animation that pops the tapped emoji at the centre of
/// the story, scales it up briefly, then fades it out. The parent screen
/// supplies the [controller] so it can re-run the animation each time a
/// new emoji is tapped.
class _StoryReactionBurst extends StatelessWidget {
  const _StoryReactionBurst({
    required this.controller,
    required this.emoji,
  });

  final AnimationController controller;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(controller);
    final opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(controller);
    final rise = Tween<double>(begin: 0, end: -40)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(controller);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Center(
          child: Transform.translate(
            offset: Offset(0, rise.value),
            child: Opacity(
              opacity: opacity.value,
              child: Transform.scale(
                scale: scale.value,
                child: Text(
                  emoji,
                  style: const TextStyle(
                    fontSize: 120,
                    shadows: [
                      Shadow(
                        color: Color(0x66000000),
                        blurRadius: 24,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StoryProgressSegment extends StatelessWidget {
  const _StoryProgressSegment({
    required this.value,
    required this.isActive,
    required this.hasStartMargin,
  });

  final double value;
  final bool isActive;
  final bool hasStartMargin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      margin: EdgeInsetsDirectional.only(start: hasStartMargin ? 4 : 0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          child: Container(
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryImage extends StatelessWidget {
  const _StoryImage({required this.story, required this.index});

  final StoryItem story;
  final int index;

  @override
  Widget build(BuildContext context) {
    final text = story.content.trim();
    if (story.hasVisualMedia) {
      return Stack(
        fit: StackFit.expand,
        children: [
          MediaPreview(
            mediaUrl: story.mediaUrl,
            mediaType: story.mediaType,
            fallbackLabel: story.isVideo ? 'فيديو' : 'صورة',
            autoplay: story.isVideo,
            showVideoControls: story.isVideo,
          ),
          if (text.isNotEmpty)
            PositionedDirectional(
              start: 24,
              end: 24,
              bottom: 48,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .58),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                  ),
                ),
              ),
            ),
        ],
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [story.color.withValues(alpha: .95), AppColors.black],
        ),
      ),
      child: CustomPaint(
        painter: _StoryArtPainter(color: story.color, index: index),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              text.isEmpty ? 'قصة من ${story.name}' : text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoryArtPainter extends CustomPainter {
  const _StoryArtPainter({required this.color, required this.index});

  final Color color;
  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    paint.color = Colors.white.withValues(alpha: .1);
    canvas.drawCircle(Offset(size.width * .24, size.height * .2), 86, paint);
    paint.color = Colors.white.withValues(alpha: .16);
    canvas.drawCircle(Offset(size.width * .84, size.height * .58), 128, paint);
    paint.color = AppColors.blue.withValues(alpha: .25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .12,
          size.height * (.62 + index * .015),
          size.width * .76,
          140,
        ),
        const Radius.circular(18),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _StoryArtPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.index != index;
  }
}

/// The pill shown at the bottom of your own story: an eye + the viewer count.
/// Tapping it opens the list of people who saw the story.
class _StoryViewersButton extends StatelessWidget {
  const _StoryViewersButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: .18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.visibility_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  count > 0 ? 'شاهدها $count' : 'لا مشاهدات بعد',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing everyone who viewed the story (creator-only — RLS
/// returns no rows to anyone else).
class _StoryViewersSheet extends StatefulWidget {
  const _StoryViewersSheet({required this.story});

  final StoryItem story;

  @override
  State<_StoryViewersSheet> createState() => _StoryViewersSheetState();
}

class _StoryViewersSheetState extends State<_StoryViewersSheet> {
  late Future<List<StoryViewer>> _viewersFuture;

  @override
  void initState() {
    super.initState();
    _viewersFuture = AppScope.read(context)
        .repositories
        .stories
        .fetchStoryViewers(widget.story.id);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      size: 20,
                      color: context.appText,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'من شاهد قصتك',
                      style: TextStyle(
                        color: context.appText,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.appBorder),
              Expanded(
                child: FutureBuilder<List<StoryViewer>>(
                  future: _viewersFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    final viewers = snapshot.data ?? const <StoryViewer>[];
                    if (viewers.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'لم يشاهد أحد قصتك بعد',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: context.appMuted,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: viewers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 2),
                      itemBuilder: (context, index) =>
                          _StoryViewerTile(viewer: viewers[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StoryViewerTile extends StatelessWidget {
  const _StoryViewerTile({required this.viewer});

  final StoryViewer viewer;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      _roleLabel(viewer.role),
      if (viewer.viewedAt != null) _relativeTime(viewer.viewedAt!),
    ].where((s) => s.isNotEmpty).join(' · ');
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: AppAvatar(
        name: viewer.name,
        radius: 22,
        color: AppColors.blue,
        imageUrl: viewer.avatarUrl,
      ),
      title: Text(
        viewer.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: context.appText,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appMuted, fontSize: 12.5),
            ),
    );
  }

  static String _roleLabel(String role) {
    return switch (role) {
      'engineer' => 'مهندس',
      'contractor' => 'شركة مقاولات',
      'craftsman' => 'حرفي',
      'worker' => 'عامل بناء',
      'machinery' => 'مزود آليات',
      _ => '',
    };
  }

  static String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) {
      return 'الآن';
    }
    if (diff.inMinutes < 60) {
      return 'قبل ${diff.inMinutes} د';
    }
    if (diff.inHours < 24) {
      return 'قبل ${diff.inHours} س';
    }
    return 'قبل ${diff.inDays} ي';
  }
}
