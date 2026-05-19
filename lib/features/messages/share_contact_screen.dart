import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/feed_post_model.dart';
import '../../models/message_item.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../state/app_scope.dart';
import 'chat_screen.dart';

class ShareContactScreen extends StatefulWidget {
  const ShareContactScreen({super.key, required this.post});

  final FeedPostModel post;

  @override
  State<ShareContactScreen> createState() => _ShareContactScreenState();
}

class _ShareContactScreenState extends State<ShareContactScreen> {
  late Future<List<MessageItem>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _contactsFuture = Future.value(const <MessageItem>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contactsFuture = AppScope.read(
      context,
    ).repositories.messages.fetchConversations();
  }

  Future<void> _sendToContact(BuildContext context, MessageItem contact) async {
    final post = widget.post;
    final isReel = post.id.startsWith('reel:') || post.isReel;
    final itemId = isReel ? post.id.replaceFirst('reel:', '') : post.id;
    final link = isReel ? 'app://reel/$itemId' : 'app://post/$itemId';
    final preview = post.body.trim().isEmpty ? post.name : post.body.trim();
    try {
      await AppScope.read(context).repositories.messages.sendMessage(
        conversationId: contact.conversationId,
        content: '$link\n$preview',
      );
      if (context.mounted) {
        AppScope.read(context).notifyMessageStateChanged();
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      AppSnack.error(context, error, fallback: 'تعذر إرسال المحتوى الآن');
      return;
    }
    if (!context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ChatScreen(contact: contact)),
    );
    messenger.showSnackBar(
      SnackBar(content: Text('تم إرسال المحتوى إلى ${contact.name}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: context.appSurface,
                border: Border(bottom: BorderSide(color: context.appBorder)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'رجوع',
                  ),
                  const Expanded(
                    child: Text(
                      'إرسال إلى',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.appSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.article_outlined, color: AppColors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'مشاركة محتوى من ${post.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<MessageItem>>(
                future: _contactsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final contacts = snapshot.data ?? const <MessageItem>[];
                  if (contacts.isEmpty) {
                    return const _NoShareContacts();
                  }
                  return ListView.separated(
                    itemCount: contacts.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: context.appBorder),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return ListTile(
                        leading: AppAvatar(
                          name: contact.name,
                          radius: 27,
                          color: contact.color,
                          imageUrl: contact.avatarUrl,
                        ),
                        title: Text(
                          contact.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        subtitle: Text(
                          contact.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: FilledButton(
                          onPressed: () => _sendToContact(context, contact),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text('إرسال'),
                        ),
                        onTap: () => _sendToContact(context, contact),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoShareContacts extends StatelessWidget {
  const _NoShareContacts();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'لا توجد محادثات لإرسال المحتوى إليها بعد',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
