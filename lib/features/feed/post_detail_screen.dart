import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/feed_post_model.dart';
import '../../models/saved_content.dart';
import '../../shared/painters/post_media_painter.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/comments_bottom_sheet.dart';
import '../../shared/widgets/like_burst.dart';
import '../../state/app_scope.dart';
import '../messages/share_contact_screen.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.post});

  final FeedPostModel post;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late int _reactionCount;
  bool _isLiked = false;
  bool _showLike = false;
  Timer? _likeBurstTimer;

  FeedPostModel get post => widget.post;

  @override
  void initState() {
    super.initState();
    _reactionCount = _parseReactionCount(post.reactions);
  }

  @override
  void dispose() {
    _likeBurstTimer?.cancel();
    super.dispose();
  }

  int _parseReactionCount(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  void _toggleLike() {
    _likeBurstTimer?.cancel();
    final shouldLike = !_isLiked;
    setState(() {
      _isLiked = shouldLike;
      _reactionCount += shouldLike ? 1 : -1;
      _showLike = shouldLike;
    });
    AppScope.read(
      context,
    ).repositories.feed.toggleLike(postId: post.id, shouldLike: shouldLike);

    if (shouldLike) {
      _likeBurstTimer = Timer(const Duration(milliseconds: 650), () {
        if (mounted) {
          setState(() => _showLike = false);
        }
      });
    }
  }

  void _openSendFlow() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ShareContactScreen(post: post)));
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'save':
        AppScope.read(context).saveContent(
          SavedContent(
            id: post.id.isEmpty ? 'post:${post.name}:${post.time}' : post.id,
            type: SavedContentType.post,
            title: post.body,
            subtitle: post.name,
            detail: 'منشور محفوظ · ${post.comments}',
          ),
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم الحفظ في المحفوظات')));
        return;
      case 'report':
        AppScope.read(
          context,
        ).repositories.feed.reportPost(postId: post.id, reason: 'user_report');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ')));
        return;
    }
  }

  Future<void> _confirmRepost() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد إعادة النشر'),
        content: const Text('هل تريد إعادة نشر هذا المنشور على صفحتك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تمت إعادة النشر')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appText,
        title: const Text(
          'المنشور',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _PostDetailCard(
                post: post,
                reactionCount: _reactionCount,
                isLiked: _isLiked,
                onLike: _toggleLike,
                onComment: () => showLinkedCommentsSheet(context),
                onRepost: _confirmRepost,
                onSend: _openSendFlow,
                onMenuSelected: _handleMenuSelection,
              ),
              const _InlineCommentsSection(),
            ],
          ),
          LikeBurst(visible: _showLike, color: AppColors.blue),
        ],
      ),
    );
  }
}

class _PostDetailCard extends StatelessWidget {
  const _PostDetailCard({
    required this.post,
    required this.reactionCount,
    required this.isLiked,
    required this.onLike,
    required this.onComment,
    required this.onRepost,
    required this.onSend,
    required this.onMenuSelected,
  });

  final FeedPostModel post;
  final int reactionCount;
  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onRepost;
  final VoidCallback onSend;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final actionColor = isLiked ? AppColors.blue : AppColors.muted;
    return Container(
      decoration: BoxDecoration(
        color: context.appSurface,
        border: Border(bottom: BorderSide(color: context.appBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppAvatar(name: post.name, radius: 28, color: post.avatarColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        post.headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.appMuted),
                      ),
                      Row(
                        children: [
                          Text(
                            post.time,
                            style: TextStyle(
                              color: context.appMuted,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(Icons.public, color: context.appMuted, size: 14),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.muted),
                  tooltip: 'خيارات المنشور',
                  onSelected: onMenuSelected,
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'save', child: Text('حفظ')),
                    PopupMenuItem(value: 'report', child: Text('إبلاغ')),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Text(
              post.body,
              style: TextStyle(
                fontSize: 16,
                height: 1.42,
                color: context.appText,
              ),
            ),
          ),
          if (post.showMedia)
            const AspectRatio(
              aspectRatio: 1.55,
              child: CustomPaint(painter: PostMediaPainter()),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                const _ReactionCircle(),
                const SizedBox(width: 6),
                Text(
                  '$reactionCount',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const Spacer(),
                Text(post.comments, style: TextStyle(color: context.appMuted)),
              ],
            ),
          ),
          Divider(height: 1, color: context.appBorder),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _PostDetailAction(
                  icon: isLiked
                      ? Icons.thumb_up_alt
                      : Icons.thumb_up_alt_outlined,
                  label: 'إعجاب',
                  color: actionColor,
                  onPressed: onLike,
                ),
                _PostDetailAction(
                  icon: Icons.mode_comment_outlined,
                  label: 'تعليق',
                  onPressed: onComment,
                ),
                _PostDetailAction(
                  icon: Icons.repeat,
                  label: 'إعادة نشر',
                  onPressed: onRepost,
                ),
                _PostDetailAction(
                  icon: Icons.send_outlined,
                  label: 'إرسال',
                  onPressed: onSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineCommentsSection extends StatelessWidget {
  const _InlineCommentsSection();

  @override
  Widget build(BuildContext context) {
    final profile = AppScope.watch(context).profile;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : 'المستخدم';

    return Container(
      color: context.appSurface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: Text(
              'التعليقات',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 26, 24, 26),
            child: Text(
              'لا توجد تعليقات بعد',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.35),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: context.appSurface,
              border: Border(top: BorderSide(color: context.appBorder)),
            ),
            child: Row(
              children: [
                AppAvatar(name: name, radius: 20, color: AppColors.darkBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'أضف تعليقا...',
                      filled: true,
                      fillColor: context.appSurfaceAlt,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 11,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide(color: context.appBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(26),
                        borderSide: BorderSide(color: context.appBorder),
                      ),
                    ),
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

class _PostDetailAction extends StatelessWidget {
  const _PostDetailAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = AppColors.muted,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 21, color: color),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          minimumSize: const Size(0, 38),
        ),
      ),
    );
  }
}

class _ReactionCircle extends StatelessWidget {
  const _ReactionCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: AppColors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: const Icon(Icons.thumb_up, color: Colors.white, size: 10),
    );
  }
}
