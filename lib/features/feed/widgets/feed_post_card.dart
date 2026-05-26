import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/feed_post_model.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../../shared/widgets/comments_bottom_sheet.dart';
import '../../../shared/widgets/media_preview.dart';
import '../../../state/app_scope.dart';
import '../../profile/profile_screen.dart';

/// Post card styled after the web `.feed-post` / `.pro-card` components:
/// theme-tinted surface, 20px radius, soft border, and Lucide-equivalent
/// action icons rendered in a clean row.
class FeedPostCard extends StatefulWidget {
  const FeedPostCard({super.key, required this.post});

  final FeedPostModel post;

  @override
  State<FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<FeedPostCard> {
  late int _reactionCount;
  bool _isLiked = false;
  Timer? _likeBurstTimer;

  FeedPostModel get post => widget.post;

  @override
  void initState() {
    super.initState();
    _reactionCount = _parseReactionCount(post.reactions);
    _isLiked = post.isLikedByViewer;
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
    });
    AppScope.read(
      context,
    ).repositories.feed.toggleLike(postId: post.id, shouldLike: _isLiked);
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

  @override
  Widget build(BuildContext context) {
    final effectiveAvatarUrl =
        _effectiveAvatarUrlFrom(AppScope.read(context).profile);
    final borderColor = context.appBorder.withValues(alpha: 0.6);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDarkMode ? 0.25 : 0.04,
            ),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // RTL start (visual right): avatar.
                GestureDetector(
                  onTap: () => _openProfile(context),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.appPrimary.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: AppAvatar(
                      name: post.name,
                      radius: 20,
                      color: post.avatarColor,
                      imageUrl: effectiveAvatarUrl,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              post.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.appText,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: context.appPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: context.appMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${post.time} • بغداد',
                            style: TextStyle(
                              color: context.appMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // RTL end (visual left): overflow menu.
                Icon(Icons.more_horiz_rounded, color: context.appMuted),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              post.body,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                color: context.appText,
                fontSize: 14.5,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (post.showMedia)
            SizedBox(
              width: double.infinity,
              height: 360,
              child: MediaPreview(
                mediaUrl: post.mediaUrl,
                mediaType: post.mediaType,
                fallbackLabel: post.isReel ? 'ريل' : 'صورة',
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Row(
              children: [
                // RTL start (visual right): like, comments, share.
                _ActionButtonWithCount(
                  icon: _isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  count: '$_reactionCount',
                  iconColor: _isLiked
                      ? const Color(0xFFF43F5E)
                      : context.appText,
                  textColor: _isLiked ? const Color(0xFFF43F5E) : null,
                  onTap: _toggleLike,
                ),
                _ActionButtonWithCount(
                  icon: Icons.mode_comment_outlined,
                  count: post.comments.replaceAll(RegExp(r'[^0-9]'), ''),
                  onTap: () => showLinkedCommentsSheet(
                    context,
                    targetType: 'post',
                    targetId: post.id,
                  ),
                ),
                _ActionButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () {},
                ),
                const Spacer(),
                // RTL end (visual left): save.
                _ActionButton(
                  icon: Icons.bookmark_outline_rounded,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: context.appText, size: 22),
        ),
      ),
    );
  }
}

class _ActionButtonWithCount extends StatelessWidget {
  const _ActionButtonWithCount({
    required this.icon,
    required this.count,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String count;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count,
                style: TextStyle(
                  color: textColor ?? context.appText,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: iconColor ?? context.appText, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
