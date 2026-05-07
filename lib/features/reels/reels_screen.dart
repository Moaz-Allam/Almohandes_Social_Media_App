import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/feed_post_model.dart';
import '../../models/reel_item.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/comments_bottom_sheet.dart';
import '../../shared/widgets/like_burst.dart';
import '../../shared/widgets/skeleton.dart';
import '../../state/app_scope.dart';
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

  late final PageController _pageController;
  late final AnimationController _progressController;
  late Future<List<ReelItem>> _reelsFuture;
  final Set<String> _likedReels = {};
  final Map<String, int> _localLikeCounts = {};
  int _index = 0;
  bool _showLike = false;
  bool _isAutoAdvancing = false;

  @override
  void initState() {
    super.initState();
    _reelsFuture = Future.value(const <ReelItem>[]);
    _pageController = PageController();
    _progressController =
        AnimationController(vsync: this, duration: _reelDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _goToNextReel();
            }
          });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reelsFuture = AppScope.read(context).repositories.reels.fetchReels();
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
    final reels = _currentReels;
    if (reels.isEmpty) {
      _progressController.stop();
      return;
    }
    _isAutoAdvancing = true;
    _progressController
      ..stop()
      ..value = 0;

    final next = (_index + 1) % reels.length;
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

  List<ReelItem> _currentReels = const [];

  void _triggerLike(ReelItem item) {
    final nextLiked = !_likedReels.contains(item.id);
    setState(() {
      if (nextLiked) {
        _likedReels.add(item.id);
      } else {
        _likedReels.remove(item.id);
      }
      final base = _localLikeCounts[item.id] ?? item.likesCount;
      _localLikeCounts[item.id] = (base + (nextLiked ? 1 : -1)).clamp(
        0,
        1 << 31,
      );
      _showLike = nextLiked;
    });
    AppScope.read(
      context,
    ).repositories.reels.toggleLike(reelId: item.id, shouldLike: nextLiked);
    if (!nextLiked) {
      return;
    }
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

  void _openSendFlow(ReelItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShareContactScreen(
          post: FeedPostModel(
            id: 'reel:${item.id}',
            profileId: item.profileId,
            name: item.name,
            headline: item.headline,
            time: 'الآن',
            body: item.caption,
            reactions: item.likesLabel,
            comments: '${item.commentsLabel} تعليق',
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
          child: FutureBuilder<List<ReelItem>>(
            future: _reelsFuture,
            builder: (context, snapshot) {
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData;
              if (isLoading) {
                return const ReelSkeleton();
              }
              final reels = snapshot.data ?? const <ReelItem>[];
              _currentReels = reels;
              if (reels.isEmpty) {
                _progressController.stop();
                return const _ReelsEmptyState();
              }
              if (!_progressController.isAnimating &&
                  _progressController.value == 0) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _restartProgress();
                  }
                });
              }
              return Stack(
                alignment: Alignment.center,
                children: [
                  PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    itemCount: reels.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      final item = reels[index];
                      final likes =
                          _localLikeCounts[item.id] ?? item.likesCount;
                      return _ReelPage(
                        item: item,
                        likesCount: likes,
                        isLiked: _likedReels.contains(item.id),
                        isActive: index == _index,
                        progress: _progressController,
                        onLike: () => _triggerLike(item),
                        onSend: () => _openSendFlow(item),
                      );
                    },
                  ),
                  LikeBurst(visible: _showLike, size: 104),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReelsEmptyState extends StatelessWidget {
  const _ReelsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_display_outlined,
              color: AppColors.muted,
              size: 48,
            ),
            SizedBox(height: 12),
            Text(
              'لا توجد ريلز بعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text(
              'ستظهر الريلز هنا بعد نشرها في Supabase.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelPage extends StatelessWidget {
  const _ReelPage({
    required this.item,
    required this.likesCount,
    required this.isLiked,
    required this.isActive,
    required this.progress,
    required this.onLike,
    required this.onSend,
  });

  final ReelItem item;
  final int likesCount;
  final bool isLiked;
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
            bottom: 78,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ReelAction(
                  icon: isLiked
                      ? Icons.thumb_up_alt
                      : Icons.thumb_up_alt_outlined,
                  label: _compactCount(likesCount),
                  color: isLiked ? AppColors.blue : Colors.white,
                  onPressed: onLike,
                ),
                const SizedBox(height: 14),
                _ReelAction(
                  icon: Icons.mode_comment_outlined,
                  label: item.commentsLabel,
                  onPressed: () => _showComments(context),
                ),
                const SizedBox(height: 14),
                _ReelAction(
                  icon: Icons.repeat,
                  label: item.repostsLabel,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'إعادة نشر الريلز ستظهر بعد تفعيل جدول المشاركات',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
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
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
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
    this.color = Colors.white,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
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
        AppColors.darkBlue,
        AppColors.black,
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

String _compactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  }
  return '$value';
}
