import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/feed_post_model.dart';
import '../../../shared/errors/user_error_message.dart';
import '../../../state/app_scope.dart';
import '../../messages/share_contact_screen.dart';

/// Bottom sheet that exposes the three ways to "share" a post:
///   1. إعادة النشر — reshare onto the viewer's own feed (keeps original
///      author attribution server-side via `repost`).
///   2. إرسال إلى محادثة — forward the post into a direct conversation.
///   3. نسخ النص — copy the post body to the clipboard.
Future<void> showSharePostSheet(BuildContext context, FeedPostModel post) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.appSurface,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) => _SharePostSheet(post: post),
  );
}

class _SharePostSheet extends StatelessWidget {
  const _SharePostSheet({required this.post});

  final FeedPostModel post;

  Future<void> _repost(BuildContext context) async {
    final app = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    navigator.pop();
    try {
      await app.repositories.feed.repost(post.id);
      app.notifyFeedChanged();
      messenger.showSnackBar(
        const SnackBar(content: Text('تمت إعادة النشر')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            userErrorMessage(error, fallback: 'تعذر إعادة النشر الآن'),
          ),
        ),
      );
    }
  }

  void _send(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(builder: (_) => ShareContactScreen(post: post)),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    navigator.pop();
    await Clipboard.setData(ClipboardData(text: post.body));
    messenger.showSnackBar(
      const SnackBar(content: Text('تم نسخ نص المنشور')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: context.appMuted.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'مشاركة المنشور',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          _ShareOptionTile(
            icon: Icons.repeat_rounded,
            label: 'إعادة النشر',
            subtitle: 'انشر هذا المنشور على صفحتك',
            onTap: () => _repost(context),
          ),
          _ShareOptionTile(
            icon: Icons.send_rounded,
            label: 'إرسال إلى محادثة',
            subtitle: 'شارك المنشور مع جهة اتصال',
            onTap: () => _send(context),
          ),
          _ShareOptionTile(
            icon: Icons.copy_rounded,
            label: 'نسخ النص',
            subtitle: 'انسخ نص المنشور إلى الحافظة',
            onTap: () => _copy(context),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ShareOptionTile extends StatelessWidget {
  const _ShareOptionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: context.appPrimary.withValues(alpha: 0.12),
        child: Icon(icon, color: context.appPrimary, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: context.appMuted, fontSize: 12.5),
      ),
    );
  }
}
