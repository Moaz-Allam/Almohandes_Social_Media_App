import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/comment_item.dart';
import '../../models/feed_post_model.dart';
import '../../models/saved_content.dart';
import '../../shared/errors/user_error_message.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/comments_bottom_sheet.dart';
import '../../shared/widgets/like_burst.dart';
import '../../shared/widgets/media_preview.dart';
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
      final feed = AppScope.read(context).repositories.feed;
      final messenger = ScaffoldMessenger.of(context);
      try {
        await feed.repost(post.id);
      } catch (error) {
        if (!mounted) {
          return;
        }
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              userErrorMessage(error, fallback: 'تعذر إعادة النشر الآن'),
            ),
          ),
        );
        return;
      }
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('تمت إعادة النشر')));
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
                onComment: () => showLinkedCommentsSheet(
                  context,
                  targetType: 'post',
                  targetId: post.id,
                ),
                onRepost: _confirmRepost,
                onSend: _openSendFlow,
                onMenuSelected: _handleMenuSelection,
              ),
              _InlineCommentsSection(postId: post.id),
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
    final profile = AppScope.watch(context).profile;
    final effectiveAvatarUrl =
        profile?.id != null && profile!.id == post.profileId
        ? profile.avatarUrl
        : post.avatarUrl;
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
                AppAvatar(
                  name: post.name,
                  radius: 28,
                  color: post.avatarColor,
                  imageUrl: effectiveAvatarUrl,
                ),
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
          if (post.isRepost && (post.repostOriginalName?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: _RepostCredit(name: post.repostOriginalName!),
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

class _RepostCredit extends StatelessWidget {
  const _RepostCredit({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.appBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.repeat, color: AppColors.blue, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'إعادة نشر من $name',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineCommentsSection extends StatefulWidget {
  const _InlineCommentsSection({required this.postId});

  final String postId;

  @override
  State<_InlineCommentsSection> createState() => _InlineCommentsSectionState();
}

class _InlineCommentsSectionState extends State<_InlineCommentsSection> {
  final _commentController = TextEditingController();
  late Future<List<CommentItem>> _commentsFuture;

  @override
  void initState() {
    super.initState();
    _commentsFuture = Future.value(const <CommentItem>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _commentsFuture = AppScope.read(context).repositories.comments
        .fetchComments(targetType: 'post', targetId: widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _commentController.clear();
    try {
      final comments = AppScope.read(context).repositories.comments;
      await comments.addComment(
        targetType: 'post',
        targetId: widget.postId,
        content: text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _commentsFuture = comments.fetchComments(
          targetType: 'post',
          targetId: widget.postId,
          forceRefresh: true,
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إضافة التعليق')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _commentController.text = text;
      AppSnack.error(context, error, fallback: 'تعذر إرسال التعليق الآن');
    }
  }

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
          FutureBuilder<List<CommentItem>>(
            future: _commentsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(26),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final comments = snapshot.data ?? const <CommentItem>[];
              if (comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.fromLTRB(24, 26, 24, 26),
                  child: Text(
                    'لا توجد تعليقات بعد',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, height: 1.35),
                  ),
                );
              }
              return Column(
                children: [
                  for (final comment in comments)
                    ListTile(
                      leading: AppAvatar(
                        name: comment.authorName,
                        radius: 18,
                        color: comment.color,
                        imageUrl: comment.avatarUrl,
                      ),
                      title: Text(comment.content),
                      subtitle: Text(
                        _exactDateTime(comment.createdAt),
                        style: TextStyle(color: context.appMuted, fontSize: 12),
                      ),
                    ),
                ],
              );
            },
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: context.appSurface,
              border: Border(top: BorderSide(color: context.appBorder)),
            ),
            child: Row(
              children: [
                AppAvatar(
                  name: name,
                  radius: 20,
                  color: AppColors.darkBlue,
                  imageUrl: profile?.avatarUrl,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    textDirection: TextDirection.rtl,
                    onSubmitted: (_) => _submitComment(),
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
                      suffixIcon: IconButton(
                        onPressed: () => _submitComment(),
                        icon: const Icon(Icons.send, color: AppColors.blue),
                        tooltip: 'إرسال التعليق',
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

  String _exactDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
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
