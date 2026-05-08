import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/feed_post_model.dart';
import '../../models/message_item.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/media_preview.dart';
import '../../state/app_scope.dart';
import '../feed/post_detail_screen.dart';
import '../reels/reels_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.contact});

  final MessageItem contact;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Future<List<ChatMessage>> _messagesFuture;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _didStartLoading = false;
  bool _isSendingText = false;
  bool _isSendingVoice = false;
  bool _isSendingFile = false;

  @override
  void initState() {
    super.initState();
    _messagesFuture = Future.value(const <ChatMessage>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartLoading) {
      return;
    }
    _didStartLoading = true;
    _messagesFuture = AppScope.read(
      context,
    ).repositories.messages.fetchMessages(widget.contact.conversationId);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSendingText) {
      return;
    }
    _messageController.clear();
    setState(() => _isSendingText = true);
    try {
      final messages = AppScope.read(context).repositories.messages;
      await messages.sendMessage(
        conversationId: widget.contact.conversationId,
        content: text,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messagesFuture = messages.fetchMessages(
          widget.contact.conversationId,
          forceRefresh: true,
        );
      });
      _scrollToLatest();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _messageController.text = text;
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isSendingText = false);
      }
    }
  }

  Future<void> _sendVoiceMessage() async {
    if (_isSendingVoice) {
      return;
    }
    final messages = AppScope.read(context).repositories.messages;
    final result = await FilePicker.pickFiles(
      type: FileType.audio,
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    final voiceUrl = file.bytes == null
        ? 'voice:${file.name}'
        : 'data:audio/mpeg;base64,${base64Encode(file.bytes!)}';
    setState(() => _isSendingVoice = true);
    try {
      await messages.sendVoiceMessage(
        conversationId: widget.contact.conversationId,
        voiceUrl: voiceUrl,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messagesFuture = messages.fetchMessages(
          widget.contact.conversationId,
          forceRefresh: true,
        );
      });
      _scrollToLatest();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isSendingVoice = false);
      }
    }
  }

  Future<void> _sendFileMessage() async {
    if (_isSendingFile) {
      return;
    }
    final messages = AppScope.read(context).repositories.messages;
    final result = await FilePicker.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    final fileUrl = file.bytes == null
        ? 'file:${file.name}'
        : 'data:${_mimeTypeForFile(file.name)};base64,${base64Encode(file.bytes!)}';
    setState(() => _isSendingFile = true);
    try {
      await messages.sendFileMessage(
        conversationId: widget.contact.conversationId,
        fileName: file.name,
        fileUrl: fileUrl,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _messagesFuture = messages.fetchMessages(
          widget.contact.conversationId,
          forceRefresh: true,
        );
      });
      _scrollToLatest();
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isSendingFile = false);
      }
    }
  }

  Future<void> _refreshMessages() async {
    setState(() {
      _messagesFuture = AppScope.read(context).repositories.messages
          .fetchMessages(widget.contact.conversationId, forceRefresh: true);
    });
    await _messagesFuture;
  }

  Future<void> _handleMenuAction(String value) async {
    final messages = AppScope.read(context).repositories.messages;
    final profileId = widget.contact.profileId;
    try {
      switch (value) {
        case 'refresh':
          await _refreshMessages();
          return;
        case 'block':
          if (profileId == null || profileId.isEmpty) {
            return;
          }
          await messages.blockConnection(profileId);
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حظر الاتصال')));
          Navigator.of(context).maybePop();
          return;
        case 'remove':
          if (profileId == null || profileId.isEmpty) {
            return;
          }
          await messages.removeConnection(profileId);
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تمت إزالة الاتصال')));
          Navigator.of(context).maybePop();
          return;
        case 'delete':
          await messages.deleteConversation(widget.contact.conversationId);
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('تم حذف المحادثة')));
          Navigator.of(context).maybePop();
          return;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(error);
    }
  }

  void _showError(Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$error')));
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
                    imageUrl: contact.avatarUrl,
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
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'خيارات المحادثة',
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Text('تحديث'),
                      ),
                      if (contact.profileId?.isNotEmpty ?? false) ...[
                        const PopupMenuItem(
                          value: 'block',
                          child: Text('حظر الاتصال'),
                        ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('إزالة الاتصال'),
                        ),
                      ],
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('حذف المحادثة'),
                      ),
                    ],
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
                  _scrollToLatest();
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageBubble(
                        text: message.text,
                        incoming: message.incoming,
                        type: message.type,
                        onOpenLink: () => _openSharedLink(message.text),
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
                    onPressed: _isSendingFile ? null : _sendFileMessage,
                    icon: _isSendingFile
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file, color: AppColors.blue),
                    tooltip: 'إرسال ملف',
                  ),
                  IconButton(
                    onPressed: _isSendingVoice ? null : _sendVoiceMessage,
                    icon: _isSendingVoice
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.mic_none_outlined,
                            color: AppColors.blue,
                          ),
                    tooltip: 'رسالة صوتية',
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
                    onPressed: _isSendingText ? null : _sendMessage,
                    icon: _isSendingText
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: AppColors.blue),
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

  void _openSharedLink(String text) {
    final lines = text.split('\n');
    final link = lines.first;
    final preview = lines.length > 1 ? lines.skip(1).join('\n') : '';
    if (link.startsWith('app://post/')) {
      final id = link.substring('app://post/'.length);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailScreen(
            post: FeedPostModel(
              id: id,
              name: widget.contact.name,
              headline: widget.contact.preview,
              time: '',
              body: preview,
              reactions: '0',
              comments: '0 تعليق',
              avatarColor: widget.contact.color,
              avatarUrl: widget.contact.avatarUrl,
              showMedia: false,
            ),
          ),
        ),
      );
      return;
    }
    if (link.startsWith('app://reel/')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReelsScreen(
            onMenu: () => Navigator.of(context).maybePop(),
            onMessages: () {},
          ),
        ),
      );
    }
  }

  String _mimeTypeForFile(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.webm')) return 'video/webm';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return 'application/octet-stream';
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
  const _MessageBubble({
    required this.text,
    required this.incoming,
    required this.type,
    required this.onOpenLink,
  });

  final String text;
  final bool incoming;
  final String type;
  final VoidCallback onOpenLink;

  @override
  Widget build(BuildContext context) {
    final mine = !incoming;
    final foreground = mine ? Colors.white : context.appText;
    final accent = mine ? Colors.white : AppColors.blue;
    return Align(
      alignment: incoming ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 292),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppColors.blue : context.appSoft,
          borderRadius: BorderRadius.circular(16).copyWith(
            topLeft: incoming ? const Radius.circular(4) : null,
            topRight: incoming ? null : const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            type == 'voice'
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        'رسالة صوتية',
                        style: TextStyle(
                          color: foreground,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  )
                : type == 'image'
                ? _ChatMediaBubble(text: text, type: 'image')
                : type == 'video'
                ? _ChatMediaBubble(text: text, type: 'video')
                : type == 'file'
                ? _FileBubble(text: text, incoming: incoming)
                : text.startsWith('app://')
                ? InkWell(
                    onTap: onOpenLink,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, color: accent, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            text.startsWith('app://reel/')
                                ? 'فتح الريل'
                                : 'فتح المنشور',
                            style: TextStyle(
                              color: accent,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
            if (mine) ...[
              const SizedBox(height: 4),
              const Icon(Icons.done_all, color: Colors.white70, size: 15),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChatMediaBubble extends StatelessWidget {
  const _ChatMediaBubble({required this.text, required this.type});

  final String text;
  final String type;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 248,
      child: AspectRatio(
        aspectRatio: 1.3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: MediaPreview(
            mediaUrl: _fileUrlFrom(text),
            mediaType: type,
            fallbackLabel: type == 'video' ? 'فيديو' : 'صورة',
            showVideoControls: type == 'video',
          ),
        ),
      ),
    );
  }
}

class _FileBubble extends StatelessWidget {
  const _FileBubble({required this.text, required this.incoming});

  final String text;
  final bool incoming;

  @override
  Widget build(BuildContext context) {
    final color = incoming ? AppColors.blue : Colors.white;
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(_fileUrlFrom(text));
        if (uri == null || !await launchUrl(uri)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تعذر فتح الملف الآن')),
            );
          }
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_outlined, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _fileNameFrom(text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: incoming ? null : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _fileNameFrom(String value) {
  final lines = value.split('\n');
  final name = lines.first.trim();
  return name.isEmpty ? 'ملف مرفق' : name;
}

String _fileUrlFrom(String value) {
  final lines = value.split('\n');
  if (lines.length < 2) {
    return value.trim();
  }
  return lines.skip(1).join('\n').trim();
}
