import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/comment_item.dart';
import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';
import 'app_avatar.dart';

Future<void> showLinkedCommentsSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
  ValueChanged<int>? onTopLevelCountDelta,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.appSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => LinkedCommentsSheet(
      targetType: targetType,
      targetId: targetId,
      onTopLevelCountDelta: onTopLevelCountDelta,
    ),
  );
}

class LinkedCommentsSheet extends StatefulWidget {
  const LinkedCommentsSheet({
    super.key,
    required this.targetType,
    required this.targetId,
    this.onTopLevelCountDelta,
  });

  final String targetType;
  final String targetId;
  // Fired with +1 when the viewer adds a top-level comment and -1 when they
  // delete one (replies don't affect the post's comment badge). Lets the
  // opener (feed card / detail header) update its counter instantly, before
  // the authoritative feed reload lands.
  final ValueChanged<int>? onTopLevelCountDelta;

  @override
  State<LinkedCommentsSheet> createState() => _LinkedCommentsSheetState();
}

class _LinkedCommentsSheetState extends State<LinkedCommentsSheet> {
  final _commentController = TextEditingController();
  final List<CommentItem> _optimisticComments = [];
  final Map<String, int> _likeDeltas = {};
  final Set<String> _likedLocally = {};
  final Map<String, int> _replyDeltas = {};
  // Comments the viewer deleted this session (hidden until the next refresh
  // confirms them server-side) and locally-edited bodies keyed by comment id.
  final Set<String> _deletedIds = {};
  final Map<String, String> _editedContent = {};
  CommentItem? _replyTarget;
  late Future<List<CommentItem>> _commentsFuture;
  bool _didStartLoading = false;

  @override
  void initState() {
    super.initState();
    _commentsFuture = Future.value(const <CommentItem>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartLoading) {
      // Already fetched. Without this guard, opening the keyboard
      // (a MediaQuery change) re-fires the network call and flashes a
      // spinner over the existing comments.
      return;
    }
    _didStartLoading = true;
    _commentsFuture = _loadAndSeedLikes(forceRefresh: false);
  }

  Future<List<CommentItem>> _loadAndSeedLikes({
    required bool forceRefresh,
  }) async {
    final comments = await AppScope.read(context).repositories.comments
        .fetchComments(
          targetType: widget.targetType,
          targetId: widget.targetId,
          forceRefresh: forceRefresh,
        );
    if (!mounted) {
      return comments;
    }
    // Seed the optimistic like-set from server truth so reopening the
    // sheet shows the comments that were previously liked already filled
    // in. Without this, the heart would always start hollow even though
    // the row exists in `app_comment_likes`.
    final liked = <String>{
      for (final comment in comments)
        if (comment.isLikedByViewer) comment.id,
    };
    if (liked.isEmpty && _likedLocally.isEmpty) {
      return comments;
    }
    setState(() {
      // Preserve any unsent toggles the user just performed and stack the
      // server snapshot on top of them.
      _likedLocally
        ..removeWhere((id) => !liked.contains(id) && !_likeDeltas.containsKey(id))
        ..addAll(liked);
    });
    return comments;
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
    final replyTo = _replyTarget;
    final profile = AppScope.read(context).profile;
    final optimistic = CommentItem(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      authorName: (profile?.fullName.isNotEmpty ?? false)
          ? profile!.fullName
          : nameForOptimisticComment,
      content: text,
      createdAt: DateTime.now(),
      color: AppColors.darkBlue,
      avatarUrl: profile?.avatarUrl,
      parentId: replyTo?.id,
    );
    _commentController.clear();
    setState(() {
      _optimisticComments.insert(0, optimistic);
      if (replyTo != null) {
        _replyDeltas.update(
          replyTo.id,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        _replyTarget = null;
      }
    });
    try {
      final comments = AppScope.read(context).repositories.comments;
      await comments.addComment(
        targetType: widget.targetType,
        targetId: widget.targetId,
        content: text,
        parentId: replyTo?.id,
      );
      if (!mounted) {
        return;
      }
      final refreshed = _loadAndSeedLikes(forceRefresh: true).then((items) {
        if (mounted) {
          setState(() {
            _optimisticComments.removeWhere(
              (item) => item.id == optimistic.id,
            );
          });
        }
        return items;
      });
      setState(() {
        _commentsFuture = refreshed;
      });
      // Refresh the feed so the post's comment counter updates "from outside"
      // (the card/detail read comments_count, which the DB trigger just bumped).
      AppScope.read(context).notifyFeedChanged();
      // Only top-level comments bump the post's comment badge (replies live
      // under their parent), matching the DB trigger on `posts.comments_count`.
      if (replyTo == null) {
        widget.onTopLevelCountDelta?.call(1);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إضافة التعليق')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _optimisticComments.removeWhere((item) => item.id == optimistic.id);
      });
      _commentController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userErrorMessage(error, fallback: 'تعذر إرسال التعليق الآن'),
          ),
        ),
      );
    }
  }

  void _toggleCommentLike(CommentItem comment) {
    final wasLiked = _isCommentLiked(comment);
    final shouldLike = !wasLiked;
    setState(() {
      if (shouldLike) {
        _likedLocally.add(comment.id);
      } else {
        _likedLocally.remove(comment.id);
      }
      _likeDeltas.update(
        comment.id,
        (value) => value + (shouldLike ? 1 : -1),
        ifAbsent: () => shouldLike ? 1 : -1,
      );
    });
    AppScope.read(context).repositories.comments.toggleCommentLike(
          commentId: comment.id,
          shouldLike: shouldLike,
        );
  }

  bool _isCommentLiked(CommentItem comment) {
    if (_likedLocally.contains(comment.id)) {
      return true;
    }
    if (_likeDeltas[comment.id] != null && _likeDeltas[comment.id]! < 0) {
      return false;
    }
    return comment.isLikedByViewer;
  }

  int _effectiveLikes(CommentItem comment) {
    final delta = _likeDeltas[comment.id] ?? 0;
    final value = comment.likesCount + delta;
    return value < 0 ? 0 : value;
  }

  int _effectiveReplies(CommentItem comment) {
    final delta = _replyDeltas[comment.id] ?? 0;
    final value = comment.repliesCount + delta;
    return value < 0 ? 0 : value;
  }

  void _startReply(CommentItem comment) {
    setState(() => _replyTarget = comment);
    FocusScope.of(context).requestFocus(FocusNode());
  }

  Future<void> _editComment(CommentItem comment) async {
    final current = _editedContent[comment.id] ?? comment.content;
    final edited = await _promptEditComment(current);
    if (edited == null || !mounted) {
      return;
    }
    final trimmed = edited.trim();
    if (trimmed.isEmpty || trimmed == comment.content) {
      return;
    }
    // Capture before the await so we don't touch context across an async gap.
    final repo = AppScope.read(context).repositories.comments;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _editedContent[comment.id] = trimmed);
    try {
      await repo.updateComment(commentId: comment.id, content: trimmed);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('تم تعديل التعليق')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _editedContent.remove(comment.id));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            userErrorMessage(error, fallback: 'تعذر تعديل التعليق'),
          ),
        ),
      );
    }
  }

  Future<String?> _promptEditComment(String initial) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('تعديل التعليق'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            minLines: 1,
            textDirection: TextDirection.rtl,
            decoration: const InputDecoration(hintText: 'عدّل تعليقك...'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text),
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteComment(CommentItem comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('حذف التعليق'),
          content: const Text('هل تريد حذف هذا التعليق؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.destructive,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final app = AppScope.read(context);
    final repo = app.repositories.comments;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _deletedIds.add(comment.id));
    try {
      await repo.deleteComment(commentId: comment.id);
      if (!mounted) {
        return;
      }
      // Deleting a top-level comment decrements the post's comments_count via
      // the DB trigger; refresh the feed so the badge updates outside the sheet.
      app.notifyFeedChanged();
      // Mirror that decrement onto the opener's badge immediately (replies
      // don't count toward the post's comment total).
      if (!comment.isReply) {
        widget.onTopLevelCountDelta?.call(-1);
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('تم حذف التعليق')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _deletedIds.remove(comment.id));
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            userErrorMessage(error, fallback: 'تعذر حذف التعليق'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    // `read` (not `watch`): we just need the avatar/name snapshot. If the
    // user updates their profile elsewhere, the sheet doesn't need to
    // repaint live — and a `watch` here would rebuild the whole sheet on
    // every unrelated AppController notify (likes, messages, etc.).
    final profile = AppScope.read(context).profile;
    final name = (profile?.fullName.isNotEmpty ?? false)
        ? profile!.fullName
        : 'المستخدم';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .78,
      minChildSize: .45,
      maxChildSize: .96,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 58,
                height: 5,
                decoration: BoxDecoration(
                  color: context.appText,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: Row(
                  children: [
                    const Text(
                      'التعليقات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'إغلاق',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<CommentItem>>(
                  future: _commentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData &&
                        _optimisticComments.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final viewerId = AppScope.read(context).profile?.id;
                    final comments = [
                      for (final raw in [
                        ..._optimisticComments,
                        ...(snapshot.data ?? const <CommentItem>[]),
                      ])
                        if (!_deletedIds.contains(raw.id))
                          _editedContent.containsKey(raw.id)
                              ? raw.copyWith(content: _editedContent[raw.id])
                              : raw,
                    ];
                    if (comments.isEmpty) {
                      return const _EmptyCommentsState();
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final isOwner =
                            viewerId != null &&
                            comment.authorId != null &&
                            comment.authorId == viewerId &&
                            !comment.id.startsWith('local-');
                        return _CommentTile(
                          comment: comment,
                          likesCount: _effectiveLikes(comment),
                          repliesCount: _effectiveReplies(comment),
                          isLiked: _isCommentLiked(comment),
                          isOwner: isOwner,
                          onLikePressed: () => _toggleCommentLike(comment),
                          onReplyPressed: () => _startReply(comment),
                          onEditPressed: () => _editComment(comment),
                          onDeletePressed: () => _deleteComment(comment),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_replyTarget != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  color: context.appSurfaceAlt,
                  child: Row(
                    children: [
                      Icon(Icons.reply, color: AppColors.blue, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'الرد على ${_replyTarget!.authorName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _replyTarget = null),
                        icon: const Icon(Icons.close),
                        iconSize: 18,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'إلغاء الرد',
                      ),
                    ],
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
                          hintText: _replyTarget == null
                              ? 'أضف تعليقا...'
                              : 'اكتب ردك...',
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
      },
    );
  }
}

const nameForOptimisticComment = 'المستخدم';

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.likesCount,
    required this.repliesCount,
    required this.isLiked,
    required this.isOwner,
    required this.onLikePressed,
    required this.onReplyPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  final CommentItem comment;
  final int likesCount;
  final int repliesCount;
  final bool isLiked;
  final bool isOwner;
  final VoidCallback onLikePressed;
  final VoidCallback onReplyPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    if (comment.isReply) {
      return _ReplyCommentTile(
        comment: comment,
        likesCount: likesCount,
        isLiked: isLiked,
        isOwner: isOwner,
        onLikePressed: onLikePressed,
        onEditPressed: onEditPressed,
        onDeletePressed: onDeletePressed,
      );
    }
    return _TopLevelCommentTile(
      comment: comment,
      likesCount: likesCount,
      repliesCount: repliesCount,
      isLiked: isLiked,
      isOwner: isOwner,
      onLikePressed: onLikePressed,
      onReplyPressed: onReplyPressed,
      onEditPressed: onEditPressed,
      onDeletePressed: onDeletePressed,
    );
  }
}

/// Overflow menu (تعديل / حذف) shown on comments the viewer owns.
class _OwnerCommentMenu extends StatelessWidget {
  const _OwnerCommentMenu({
    required this.onEditPressed,
    required this.onDeletePressed,
    this.size = 18,
  });

  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 10,
      height: size + 10,
      child: PopupMenuButton<String>(
        tooltip: 'خيارات',
        padding: EdgeInsets.zero,
        icon: Icon(Icons.more_horiz, size: size, color: context.appMuted),
        onSelected: (value) {
          if (value == 'edit') {
            onEditPressed();
          } else if (value == 'delete') {
            onDeletePressed();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined, size: 18),
                SizedBox(width: 10),
                Text('تعديل'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: AppColors.destructive),
                SizedBox(width: 10),
                Text('حذف', style: TextStyle(color: AppColors.destructive)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _exactCommentDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}

class _TopLevelCommentTile extends StatelessWidget {
  const _TopLevelCommentTile({
    required this.comment,
    required this.likesCount,
    required this.repliesCount,
    required this.isLiked,
    required this.isOwner,
    required this.onLikePressed,
    required this.onReplyPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  final CommentItem comment;
  final int likesCount;
  final int repliesCount;
  final bool isLiked;
  final bool isOwner;
  final VoidCallback onLikePressed;
  final VoidCallback onReplyPressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            name: comment.authorName,
            radius: 18,
            color: comment.color,
            imageUrl: comment.avatarUrl,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    if (isOwner)
                      _OwnerCommentMenu(
                        onEditPressed: onEditPressed,
                        onDeletePressed: onDeletePressed,
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.content,
                  style: const TextStyle(height: 1.35, fontSize: 14.5),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _exactCommentDateTime(comment.createdAt),
                      style: TextStyle(
                        color: context.appMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: onLikePressed,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: isLiked
                                  ? AppColors.roseAccent
                                  : context.appMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$likesCount',
                              style: TextStyle(
                                color: isLiked
                                    ? AppColors.roseAccent
                                    : context.appMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onReplyPressed,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.reply,
                              size: 16,
                              color: context.appMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              repliesCount > 0
                                  ? 'رد · $repliesCount'
                                  : 'رد',
                              style: TextStyle(
                                color: context.appMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reply pill — visually attached to its parent comment via a thread line
/// on the leading edge, with a softer background and a compact layout.
class _ReplyCommentTile extends StatelessWidget {
  const _ReplyCommentTile({
    required this.comment,
    required this.likesCount,
    required this.isLiked,
    required this.isOwner,
    required this.onLikePressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  final CommentItem comment;
  final int likesCount;
  final bool isLiked;
  final bool isOwner;
  final VoidCallback onLikePressed;
  final VoidCallback onEditPressed;
  final VoidCallback onDeletePressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 42,
        top: 2,
        bottom: 2,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thread line linking the reply to its parent comment.
            Container(
              width: 2,
              margin: const EdgeInsetsDirectional.only(end: 10, top: 4, bottom: 4),
              decoration: BoxDecoration(
                color: context.appBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: context.appSurfaceAlt,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(12),
                  ),
                  border: Border.all(color: context.appBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_left,
                      size: 14,
                      color: context.appMuted,
                    ),
                    const SizedBox(width: 6),
                    AppAvatar(
                      name: comment.authorName,
                      radius: 12,
                      color: comment.color,
                      imageUrl: comment.avatarUrl,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  comment.authorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: context.appText,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '· رد',
                                style: TextStyle(
                                  color: context.appMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (isOwner) ...[
                                const Spacer(),
                                _OwnerCommentMenu(
                                  onEditPressed: onEditPressed,
                                  onDeletePressed: onDeletePressed,
                                  size: 15,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 1),
                          Text(
                            comment.content,
                            style: const TextStyle(
                              height: 1.35,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Text(
                                _exactCommentDateTime(comment.createdAt),
                                style: TextStyle(
                                  color: context.appMuted,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 10),
                              InkWell(
                                onTap: onLikePressed,
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                    vertical: 2,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        size: 13,
                                        color: isLiked
                                            ? AppColors.roseAccent
                                            : context.appMuted,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '$likesCount',
                                        style: TextStyle(
                                          color: isLiked
                                              ? AppColors.roseAccent
                                              : context.appMuted,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
          ],
        ),
      ),
    );
  }
}

class _EmptyCommentsState extends StatelessWidget {
  const _EmptyCommentsState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 54, 24, 24),
      children: [
        const Icon(
          Icons.mode_comment_outlined,
          color: AppColors.muted,
          size: 44,
        ),
        const SizedBox(height: 12),
        const Text(
          'لا توجد تعليقات بعد',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        const Text(
          'اكتب أول تعليق من الحقل بالأسفل.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, height: 1.45),
        ),
      ],
    );
  }
}
