import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/message_item.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../state/app_scope.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.contact});

  final MessageItem contact;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Future<List<ChatMessage>> _messagesFuture;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messagesFuture = Future.value(const <ChatMessage>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messagesFuture = AppScope.read(
      context,
    ).repositories.messages.fetchMessages(widget.contact.conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }
    _messageController.clear();
    await AppScope.read(context).repositories.messages.sendMessage(
      conversationId: widget.contact.conversationId,
      content: text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _messagesFuture = AppScope.read(context).repositories.messages
          .fetchMessages(widget.contact.conversationId, forceRefresh: true);
    });
  }

  Future<void> _refreshMessages() async {
    setState(() {
      _messagesFuture = AppScope.read(context).repositories.messages
          .fetchMessages(widget.contact.conversationId, forceRefresh: true);
    });
    await _messagesFuture;
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 62,
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
                  AppAvatar(
                    name: contact.name,
                    radius: 22,
                    color: contact.color,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      contact.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _refreshMessages,
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'تحديث',
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ChatMessage>>(
                future: _messagesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data ?? const <ChatMessage>[];
                  if (messages.isEmpty) {
                    return const _EmptyChatState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageBubble(
                        text: message.text,
                        incoming: message.incoming,
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: context.appSurface,
                border: Border(top: BorderSide(color: context.appBorder)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('إرفاق الملفات غير مفعّل بعد'),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.blue,
                    ),
                    tooltip: 'إضافة',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 3,
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالة...',
                        filled: true,
                        fillColor: context.appSoft,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.blue),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: AppColors.blue),
                    tooltip: 'إرسال',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'لا توجد رسائل بعد',
        style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.incoming});

  final String text;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: incoming ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 292),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: incoming ? context.appSoft : context.appPaleBlue,
          borderRadius: BorderRadius.circular(16).copyWith(
            topRight: incoming ? const Radius.circular(4) : null,
            topLeft: incoming ? null : const Radius.circular(4),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15, height: 1.35)),
      ),
    );
  }
}
