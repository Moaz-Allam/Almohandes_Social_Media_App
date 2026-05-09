import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/feed_post_model.dart';
import '../../models/reel_item.dart';
import '../../shared/errors/user_error_message.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/comments_bottom_sheet.dart';
import '../../shared/widgets/like_burst.dart';
import '../../shared/widgets/media_preview.dart';
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

class _ReelsScreenState extends State<ReelsScreen> {
  late final PageController _pageController;
  late Future<List<ReelItem>> _reelsFuture;
  final Set<String> _likedReels = {};
  final Map<String, int> _localLikeCounts = {};
  int _index = 0;
  bool _showLike = false;
  bool _didStartLoading = false;

  @override
  void initState() {
    super.initState();
    _reelsFuture = Future.value(const <ReelItem>[]);
    _pageController = PageController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartLoading) {
      return;
    }
    _didStartLoading = true;
    _reelsFuture = AppScope.read(context).repositories.reels.fetchReels();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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
  }

  void _openSendFlow(ReelItem item) {
    final profile = AppScope.read(context).profile;
    final avatarUrl = profile?.id != null && profile!.id == item.profileId
        ? profile.avatarUrl
        : item.avatarUrl;
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
            avatarUrl: avatarUrl,
            showMedia: false,
            mediaUrl: item.videoUrl ?? item.thumbnailUrl ?? '',
            mediaType: 'reel',
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
                return const Center(child: CircularProgressIndicator());
              }
              final reels = snapshot.data ?? const <ReelItem>[];
              if (reels.isEmpty) {
                return const _ReelsEmptyState();
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
              'ستظهر الريلز هنا بعد نشرها.',
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
    required this.onLike,
    required this.onSend,
  });

  final ReelItem item;
  final int likesCount;
  final bool isLiked;
  final bool isActive;
  final VoidCallback onLike;
  final VoidCallback onSend;

  void _showComments(BuildContext context) {
    showLinkedCommentsSheet(context, targetType: 'reel', targetId: item.id);
  }

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.watch(context).profile;
    final effectiveAvatarUrl =
        profile?.id != null && profile!.id == item.profileId
        ? profile.avatarUrl
        : item.avatarUrl;
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _ReelBackdropPainter(item.color)),
          if ((item.videoUrl ?? item.thumbnailUrl ?? '').isNotEmpty)
            Positioned.fill(
              child: MediaPreview(
                mediaUrl: item.videoUrl ?? item.thumbnailUrl ?? '',
                mediaType: 'reel',
                fallbackLabel: 'ريل',
                autoplay: isActive,
                showVideoControls: true,
              ),
            ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: onLike,
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
                  onPressed: () async {
                    try {
                      await AppScope.read(
                        context,
                      ).repositories.reels.repost(item.id);
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              userErrorMessage(
                                error,
                                fallback: 'تعذر إعادة نشر الريل الآن',
                              ),
                            ),
                          ),
                        );
                      }
                      return;
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تمت إعادة نشر الريل')),
                      );
                    }
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
                    AppAvatar(
                      name: item.name,
                      radius: 25,
                      color: item.color,
                      imageUrl: effectiveAvatarUrl,
                    ),
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
