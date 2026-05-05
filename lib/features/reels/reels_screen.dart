import 'package:flutter/material.dart';

import '../../models/feed_post_model.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/comments_bottom_sheet.dart';
import '../../shared/widgets/like_burst.dart';
import '../home/widgets/home_top_bar.dart';
import '../messages/share_contact_screen.dart';

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({
    super.key,
    required this.onMenu,
    required this.onMessages,
  });

  final VoidCallback onMenu;
  final VoidCallback onMessages;

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen>
    with SingleTickerProviderStateMixin {
  static const _reelDuration = Duration(seconds: 7);

  static const _reels = [
    _ReelItem(
      name: 'ناتالي منصور',
      headline: 'صوت رائد في لينكدإن · محتوى مهني',
      caption: 'أفضل لحظة اليوم كانت مشاركة تجربة بناء مجتمع مهني حقيقي.',
      likes: '18K',
      comments: '650',
      reposts: '97',
      color: Color(0xFF435A78),
    ),
    _ReelItem(
      name: 'ريم حسن',
      headline: 'مصممة منتجات رقمية',
      caption: 'لقطة سريعة من ورشة تصميم رحلة التسجيل الجديدة.',
      likes: '8.2K',
      comments: '214',
      reposts: '32',
      color: Color(0xFF7A54C7),
    ),
    _ReelItem(
      name: 'أحمد منصور',
      headline: 'مطور Flutter',
      caption: 'كيف حولنا نموذج أولي إلى تجربة موبايل أكثر سلاسة.',
      likes: '5.7K',
      comments: '141',
      reposts: '28',
      color: Color(0xFF0A66C2),
    ),
  ];

  late final PageController _pageController;
  late final AnimationController _progressController;
  int _index = 0;
  bool _showLike = false;
  bool _isAutoAdvancing = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _progressController =
        AnimationController(vsync: this, duration: _reelDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _goToNextReel();
            }
          });
    _restartProgress();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _restartProgress() {
    _progressController.forward(from: 0);
  }

  void _goToNextReel() {
    if (_isAutoAdvancing) {
      return;
    }
    _isAutoAdvancing = true;
    _progressController
      ..stop()
      ..value = 0;

    final next = (_index + 1) % _reels.length;
    setState(() => _index = next);

    if (!_pageController.hasClients) {
      _isAutoAdvancing = false;
      _restartProgress();
      return;
    }
    _pageController
        .animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        )
        .whenComplete(() {
          if (!mounted) {
            return;
          }
          _isAutoAdvancing = false;
          _restartProgress();
        });
  }

  void _triggerLike() {
    setState(() => _showLike = true);
    Future<void>.delayed(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _showLike = false);
      }
    });
  }

  void _onPageChanged(int value) {
    setState(() => _index = value);
    if (!_isAutoAdvancing) {
      _restartProgress();
    }
  }

  void _openSendFlow(_ReelItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShareContactScreen(
          post: FeedPostModel(
            name: item.name,
            headline: item.headline,
            time: 'الآن',
            body: item.caption,
            reactions: item.likes,
            comments: item.comments,
            avatarColor: item.color,
            showMedia: false,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HomeTopBar(
          onMenu: widget.onMenu,
          onMessages: widget.onMessages,
          hint: 'ابحث في ريلز',
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: _reels.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _ReelPage(
                    item: _reels[index],
                    isActive: index == _index,
                    progress: _progressController,
                    onLike: _triggerLike,
                    onSend: () => _openSendFlow(_reels[index]),
                  );
                },
              ),
              LikeBurst(visible: _showLike, size: 104),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReelPage extends StatelessWidget {
  const _ReelPage({
    required this.item,
    required this.isActive,
    required this.progress,
    required this.onLike,
    required this.onSend,
  });

  final _ReelItem item;
  final bool isActive;
  final Animation<double> progress;
  final VoidCallback onLike;
  final VoidCallback onSend;

  void _showComments(BuildContext context) {
    showLinkedCommentsSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _ReelBackdropPainter(item.color)),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: onLike,
            ),
          ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 62,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReelAction(
                  icon: Icons.thumb_up_alt_outlined,
                  label: item.likes,
                  onPressed: onLike,
                ),
                const SizedBox(height: 18),
                _ReelAction(
                  icon: Icons.mode_comment_outlined,
                  label: item.comments,
                  onPressed: () => _showComments(context),
                ),
                const SizedBox(height: 18),
                _ReelAction(
                  icon: Icons.repeat,
                  label: item.reposts,
                  onPressed: () {},
                ),
                const SizedBox(height: 18),
                _ReelAction(
                  icon: Icons.send_outlined,
                  label: '',
                  onPressed: onSend,
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: 72,
            bottom: 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppAvatar(name: item.name, radius: 25, color: item.color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                  minimumSize: const Size(72, 34),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Text('متابعة'),
                              ),
                            ],
                          ),
                          Text(
                            item.headline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  item.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: isActive ? progress.value : 0,
                    minHeight: 5,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReelAction extends StatelessWidget {
  const _ReelAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 25),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReelBackdropPainter extends CustomPainter {
  const _ReelBackdropPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = true;
    final rect = Offset.zero & size;
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: .95),
        const Color(0xFF19202A),
        Colors.black,
      ],
    ).createShader(rect);
    canvas.drawRect(rect, paint);
    paint.shader = null;

    paint.color = Colors.white.withValues(alpha: .16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .18,
          size.height * .16,
          size.width * .64,
          118,
        ),
        const Radius.circular(24),
      ),
      paint,
    );
    paint.color = Colors.white.withValues(alpha: .22);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(size.width * (.22 + i * .18), size.height * (.38 + i * .045)),
        52,
        paint,
      );
    }
    paint.color = Colors.black.withValues(alpha: .32);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * .72, size.width, size.height * .28),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ReelBackdropPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _ReelItem {
  const _ReelItem({
    required this.name,
    required this.headline,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.reposts,
    required this.color,
  });

  final String name;
  final String headline;
  final String caption;
  final String likes;
  final String comments;
  final String reposts;
  final Color color;
}
