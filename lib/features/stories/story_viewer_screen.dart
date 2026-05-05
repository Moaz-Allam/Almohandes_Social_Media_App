import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/story_item.dart';
import '../../shared/widgets/app_avatar.dart';

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
    with SingleTickerProviderStateMixin {
  static const _storyDuration = Duration(seconds: 6);

  late final PageController _controller;
  late final AnimationController _progress;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
    _progress = AnimationController(vsync: this, duration: _storyDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _goNext();
        }
      })
      ..forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _restartProgress() {
    _progress.forward(from: 0);
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
    final currentStory = widget.stories[_index];

    return Scaffold(
      key: const ValueKey('story-viewer'),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragEnd: _handleDrag,
          onTapUp: (details) {
            final width = MediaQuery.sizeOf(context).width;
            if (details.localPosition.dx < width / 2) {
              _goNext();
            } else {
              _goPrevious();
            }
          },
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.stories.length,
                onPageChanged: (value) {
                  setState(() => _index = value);
                  _restartProgress();
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
                        Text(
                          currentStory.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        AppAvatar(
                          name: currentStory.name,
                          radius: 22,
                          color: currentStory.color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [story.color.withValues(alpha: .95), const Color(0xFF111111)],
        ),
      ),
      child: CustomPaint(
        painter: _StoryArtPainter(color: story.color, index: index),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'قصة من ${story.name}',
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
