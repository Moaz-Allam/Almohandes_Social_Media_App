import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/feed_post_model.dart';
import '../../state/app_scope.dart';
import '../feed/post_detail_screen.dart';
import '../listings/my_listings_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';
import '../reels/reels_screen.dart';

/// Parses a notification `action_url` and routes the user to the matching
/// destination. Supported schemes (emitted by the server-side notification
/// triggers):
///
///   * `app://post/<postId>`        → post detail
///   * `app://comment/<commentId>`  → the post/reel the comment belongs to
///   * `app://reel/<reelId>`        → reels feed
///   * `app://profile/<profileId>`  → that user's profile
///   * `app://chat/<id>`            → messages list
///   * `app://project/<id>`         → owner's listings management
///   * `app://job/<id>`             → owner's listings management
///   * `app://work/<id>`            → current user's profile (الأعمال tab)
///
/// Returns true if the URL was recognised and navigation was attempted, even
/// if the target row no longer exists (so callers can still mark the
/// notification read). Returns false for unknown / empty URLs.
Future<bool> openNotificationAction(
  BuildContext context,
  String? actionUrl,
) async {
  final url = actionUrl?.trim() ?? '';
  const scheme = 'app://';
  if (!url.startsWith(scheme)) {
    return false;
  }
  final rest = url.substring(scheme.length);
  final slash = rest.indexOf('/');
  if (slash <= 0) {
    return false;
  }
  final kind = rest.substring(0, slash);
  final id = rest.substring(slash + 1).trim();
  if (id.isEmpty) {
    return false;
  }

  final app = AppScope.read(context);
  final navigator = Navigator.of(context);

  switch (kind) {
    case 'post':
      final post = await app.repositories.feed.fetchPostById(id);
      if (!context.mounted) {
        return true;
      }
      navigator.push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(post: post ?? _placeholderPost(id)),
        ),
      );
      return true;

    case 'comment':
      final target = await app.repositories.comments.resolveCommentTarget(id);
      if (!context.mounted) {
        return true;
      }
      if (target == null) {
        return true;
      }
      if (target.targetType == 'reel') {
        _openReels(navigator);
        return true;
      }
      final post = await app.repositories.feed.fetchPostById(target.targetId);
      if (!context.mounted) {
        return true;
      }
      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              PostDetailScreen(post: post ?? _placeholderPost(target.targetId)),
        ),
      );
      return true;

    case 'reel':
      _openReels(navigator);
      return true;

    case 'profile':
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ProfileScreen(
            profileId: id,
            name: '',
            headline: '',
            color: AppColors.darkBlue,
          ),
        ),
      );
      return true;

    case 'chat':
      navigator.push(
        MaterialPageRoute(builder: (_) => const MessagesScreen()),
      );
      return true;

    case 'project':
    case 'job':
      // Application-received / match notifications. The owner manages the
      // applicants from their listings screen.
      navigator.push(
        MaterialPageRoute(builder: (_) => const MyListingsScreen()),
      );
      return true;

    case 'work':
      // "You were matched" — surface the user's own profile (الأعمال tab).
      navigator.push(
        MaterialPageRoute(builder: (_) => const ProfileScreen.me()),
      );
      return true;

    default:
      // Unknown / unsupported (e.g. story) — nothing to open.
      return false;
  }
}

void _openReels(NavigatorState navigator) {
  navigator.push(
    MaterialPageRoute(
      builder: (routeContext) => ReelsScreen(
        onMenu: () => Navigator.of(routeContext).maybePop(),
        onMessages: () {},
      ),
    ),
  );
}

/// Minimal post used when the row couldn't be loaded (deleted, RLS-hidden, or
/// offline). The detail screen still opens and shows comments by id.
FeedPostModel _placeholderPost(String id) {
  return FeedPostModel(
    id: id,
    name: 'منشور',
    headline: '',
    time: '',
    body: '',
    reactions: '0',
    comments: '0 تعليق',
    avatarColor: AppColors.darkBlue,
    showMedia: false,
  );
}
