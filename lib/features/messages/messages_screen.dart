import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/message_item.dart';
import '../../state/app_scope.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import 'chat_screen.dart';
import 'widgets/message_tile.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
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

  Future<void> _refresh() async {
    setState(() {
      _contactsFuture = AppScope.read(
        context,
      ).repositories.messages.fetchConversations(forceRefresh: true);
    });
    await _contactsFuture;
  }

  void _openChat(BuildContext context, MessageItem contact) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ChatScreen(contact: contact)));
  }

  void _openProfile(BuildContext context, MessageItem contact) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          profileId: contact.profileId,
          name: contact.name,
          headline: contact.preview,
          color: contact.color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const SizedBox(width: 2),
                  const Expanded(
                    child: Text(
                      'الرسائل',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'تحديث',
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'رسالة جديدة',
                  ),
                ],
              ),
            ),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: context.appSurface,
                border: Border(bottom: BorderSide(color: context.appBorder)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: context.appMuted, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'بحث في الرسائل',
                      style: TextStyle(color: context.appMuted),
                    ),
                  ),
                  Icon(Icons.tune, color: context.appMuted, size: 20),
                ],
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
                    return const _MessagesEmptyState();
                  }
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      itemCount: contacts.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 78,
                        color: context.appBorder,
                      ),
                      itemBuilder: (context, index) => MessageTile(
                        item: contacts[index],
                        onTap: () => _openChat(context, contacts[index]),
                        onProfileTap: () =>
                            _openProfile(context, contacts[index]),
                      ),
                    ),
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

class _MessagesEmptyState extends StatelessWidget {
  const _MessagesEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, color: AppColors.muted, size: 46),
            SizedBox(height: 12),
            Text(
              'لا توجد محادثات بعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text(
              'ستظهر المحادثات هنا بعد إنشائها في Supabase.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
