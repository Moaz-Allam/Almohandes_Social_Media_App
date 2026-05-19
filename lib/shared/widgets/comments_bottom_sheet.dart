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
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.appSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) =>
        LinkedCommentsSheet(targetType: targetType, targetId: targetId),
  );
}

class LinkedCommentsSheet extends StatefulWidget {
  const LinkedCommentsSheet({
    super.key,
    required this.targetType,
    required this.targetId,
  });

  final String targetType;
  final String targetId;

  @override
  State<LinkedCommentsSheet> createState() => _LinkedCommentsSheetState();
}

class _LinkedCommentsSheetState extends State<LinkedCommentsSheet> {
  final _commentController = TextEditingController();
  final List<CommentItem> _optimisticComments = [];
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
    _commentsFuture = AppScope.read(context).repositories.comments
        .fetchComments(
          targetType: widget.targetType,
          targetId: widget.targetId,
        );
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
    );
    _commentController.clear();
    setState(() => _optimisticComments.insert(0, optimistic));
    try {
      final comments = AppScope.read(context).repositories.comments;
      await comments.addComment(
        targetType: widget.targetType,
        targetId: widget.targetId,
        content: text,
      );
      if (!mounted) {
        return;
      }
      final refreshed = comments
          .fetchComments(
            targetType: widget.targetType,
            targetId: widget.targetId,
            forceRefresh: true,
          )
          .then((items) {
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
                    final comments = [
                      ..._optimisticComments,
                      ...(snapshot.data ?? const <CommentItem>[]),
                    ];
                    if (comments.isEmpty) {
                      return const _EmptyCommentsState();
                    }
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: AppAvatar(
                            name: comment.authorName,
                            radius: 18,
                            color: comment.color,
                            imageUrl: comment.avatarUrl,
                          ),
                          title: Text(
                            comment.content,
                            style: const TextStyle(height: 1.35),
                          ),
                          subtitle: Text(
                            _exactDateTime(comment.createdAt),
                            style: TextStyle(
                              color: context.appMuted,
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    );
                  },
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
      },
    );
  }

  String _exactDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}

const nameForOptimisticComment = 'المستخدم';

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
