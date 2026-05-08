import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/feed_post_model.dart';
import '../../../models/saved_content.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/comments_bottom_sheet.dart';
import '../../../shared/widgets/like_burst.dart';
import '../../../shared/widgets/media_preview.dart';
import '../../../state/app_scope.dart';
import '../../messages/share_contact_screen.dart';
import '../../profile/profile_screen.dart';

class FeedPostCard extends StatefulWidget {
  const FeedPostCard({super.key, required this.post});

  final FeedPostModel post;

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
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

  int _parseReactionCount(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  String? _effectiveAvatarUrlFrom(dynamic profile) {
    if (profile?.id != null && profile!.id == post.profileId) {
      return profile.avatarUrl;
    }
    return post.avatarUrl;
  }

  @override
  void dispose() {
    _likeBurstTimer?.cancel();
    super.dispose();
  }

  void _toggleLike() {
    _likeBurstTimer?.cancel();
    setState(() {
      _isLiked = !_isLiked;
      _reactionCount += _isLiked ? 1 : -1;
      _showLike = _isLiked;
    });
    AppScope.read(
      context,
    ).repositories.feed.toggleLike(postId: post.id, shouldLike: _isLiked);

    if (!_isLiked) {
      return;
    }

    _likeBurstTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        setState(() => _showLike = false);
      }
    });
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          profileId: post.profileId,
          name: post.name,
          headline: post.headline,
          color: post.avatarColor,
          avatarUrl: _effectiveAvatarUrlFrom(AppScope.read(context).profile),
        ),
      ),
    );
  }

  void _showComments(BuildContext context) {
    showLinkedCommentsSheet(context, targetType: 'post', targetId: post.id);
  }

  void _openSendFlow(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ShareContactScreen(post: post)));
  }

  void _handleMenuSelection(BuildContext context, String value) {
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

  Future<void> _confirmRepost(BuildContext context) async {
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

    if (confirmed == true && context.mounted) {
      final feed = AppScope.read(context).repositories.feed;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await feed.repost(post.id);
      } catch (error) {
        if (!context.mounted) {
          return;
        }
        messenger.showSnackBar(SnackBar(content: Text('$error')));
        return;
      }
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('تمت إعادة النشر')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAvatarUrl = _effectiveAvatarUrlFrom(
      AppScope.watch(context).profile,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: context.appSurface,
            border: Border(
              top: BorderSide(color: context.appBorder),
              bottom: BorderSide(color: context.appBorder),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _openProfile(context),
                      child: AppAvatar(
                        name: post.name,
                        radius: 28,
                        color: post.avatarColor,
                        imageUrl: effectiveAvatarUrl,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _openProfile(context),
                        child: _PostHeader(post: post),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppColors.muted),
                      tooltip: 'خيارات المنشور',
                      onSelected: (value) =>
                          _handleMenuSelection(context, value),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'save', child: Text('حفظ')),
                        PopupMenuItem(value: 'report', child: Text('إبلاغ')),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Text(
                  post.body,
                  style: TextStyle(
                    fontSize: 15.5,
                    height: 1.36,
                    color: context.appText,
                  ),
                ),
              ),
              if (post.showMedia)
                AspectRatio(
                  aspectRatio: 1.55,
                  child: MediaPreview(
                    mediaUrl: post.mediaUrl,
                    mediaType: post.mediaType,
                    fallbackLabel: post.isReel ? 'ريل' : 'صورة',
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Row(
                  children: [
                    const _ReactionIcon(),
                    const SizedBox(width: 6),
                    Text(
                      '$_reactionCount',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const Spacer(),
                    Text(
                      post.comments,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: context.appBorder),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    PostAction(
                      key: ValueKey('post-like-action-${post.name}'),
                      icon: _isLiked
                          ? Icons.thumb_up_alt
                          : Icons.thumb_up_alt_outlined,
                      label: 'إعجاب',
                      color: _isLiked ? AppColors.blue : AppColors.muted,
                      onPressed: _toggleLike,
                    ),
                    PostAction(
                      icon: Icons.mode_comment_outlined,
                      label: 'تعليق',
                      onPressed: () => _showComments(context),
                    ),
                    PostAction(
                      icon: Icons.repeat,
                      label: 'إعادة نشر',
                      onPressed: () => _confirmRepost(context),
                    ),
                    PostAction(
                      icon: Icons.send_outlined,
                      label: 'إرسال',
                      onPressed: () => _openSendFlow(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        LikeBurst(visible: _showLike, color: AppColors.blue),
      ],
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});

  final FeedPostModel post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(color: context.appText, fontSize: 16),
            children: [
              TextSpan(
                text: post.name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          post.headline,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: context.appMuted, fontSize: 14),
        ),
        Row(
          children: [
            Text(
              post.time,
              style: TextStyle(color: context.appMuted, fontSize: 13),
            ),
            const SizedBox(width: 5),
            Icon(Icons.public, color: context.appMuted, size: 14),
          ],
        ),
      ],
    );
  }
}

class _ReactionIcon extends StatelessWidget {
  const _ReactionIcon();

  @override
  Widget build(BuildContext context) {
    return const _ReactionCircle(
      color: AppColors.blue,
      icon: Icons.thumb_up,
      size: 18,
    );
  }
}

class _ReactionCircle extends StatelessWidget {
  const _ReactionCircle({
    required this.color,
    required this.icon,
    required this.size,
  });

  final Color color;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Icon(icon, color: Colors.white, size: size * .58),
    );
  }
}

class PostAction extends StatelessWidget {
  const PostAction({
    super.key,
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
