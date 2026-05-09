import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/feed_post_model.dart';
import '../../models/message_item.dart';
import '../../shared/errors/user_error_message.dart';
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
  final List<ChatMessage> _optimisticMessages = [];
  final _voiceRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _voiceSubscription;
  BytesBuilder? _voiceBytes;
  bool _didStartLoading = false;
  bool _isSendingText = false;
  bool _isSendingVoice = false;
  bool _isRecordingVoice = false;
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
    _messagesFuture = AppScope.read(context).repositories.messages
        .fetchMessages(widget.contact.conversationId)
        .then((items) {
          if (mounted) {
            AppScope.read(context).notifyMessageStateChanged();
          }
          return items;
        });
  }

  @override
  void dispose() {
    _voiceSubscription?.cancel();
    _voiceRecorder.dispose();
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
    final optimistic = _optimisticMessage(text: text, type: 'text');
    setState(() {
      _isSendingText = true;
      _optimisticMessages.add(optimistic);
    });
    AppScope.read(context).notifyMessageStateChanged();
    _scrollToLatest();
    try {
      final messages = AppScope.read(context).repositories.messages;
      await messages.sendMessage(
        conversationId: widget.contact.conversationId,
        content: text,
      );
      if (!mounted) {
        return;
      }
      _refreshMessagesAfterSend(optimistic.id);
      _scrollToLatest();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _optimisticMessages.removeWhere(
          (message) => message.id == optimistic.id,
        );
      });
      _messageController.text = text;
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _isSendingText = false);
      }
    }
  }

  Future<void> _toggleVoiceRecording() async {
    if (_isRecordingVoice) {
      await _stopAndSendVoiceMessage();
      return;
    }
    await _startVoiceRecording();
  }

  Future<void> _startVoiceRecording() async {
    if (_isSendingVoice || _isRecordingVoice) {
      return;
    }
    try {
      final hasPermission = await _voiceRecorder.hasPermission();
      if (!mounted) {
        return;
      }
      if (!hasPermission) {
        _showError('اسمح باستخدام الميكروفون لتسجيل رسالة صوتية');
        return;
      }
      final stream = await _voiceRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      _voiceBytes = BytesBuilder(copy: false);
      await _voiceSubscription?.cancel();
      _voiceSubscription = stream.listen(
        (chunk) => _voiceBytes?.add(chunk),
        onError: (error) {
          if (mounted) {
            _showError(error);
          }
        },
      );
      if (mounted) {
        setState(() => _isRecordingVoice = true);
      }
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    }
  }

  Future<void> _stopAndSendVoiceMessage() async {
    if (_isSendingVoice) {
      return;
    }
    final app = AppScope.read(context);
    final messages = app.repositories.messages;
    setState(() {
      _isRecordingVoice = false;
      _isSendingVoice = true;
    });
    try {
      await _voiceRecorder.stop();
      await _voiceSubscription?.cancel();
      _voiceSubscription = null;
      final pcmBytes = _voiceBytes?.takeBytes() ?? Uint8List(0);
      _voiceBytes = null;
      if (pcmBytes.isEmpty) {
        _showError('لم يتم تسجيل صوت واضح');
        return;
      }
      final voiceUrl =
          'data:audio/wav;base64,${base64Encode(_wavFromPcm16(pcmBytes))}';
      final optimistic = _optimisticMessage(text: voiceUrl, type: 'voice');
      setState(() => _optimisticMessages.add(optimistic));
      app.notifyMessageStateChanged();
      _scrollToLatest();
      try {
        await messages.sendVoiceMessage(
          conversationId: widget.contact.conversationId,
          voiceUrl: voiceUrl,
        );
        if (!mounted) {
          return;
        }
        _refreshMessagesAfterSend(optimistic.id);
        _scrollToLatest();
      } catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _optimisticMessages.removeWhere(
            (message) => message.id == optimistic.id,
          );
        });
        _showError(error);
      }
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingVoice = false);
      }
    }
  }

  Uint8List _wavFromPcm16(Uint8List pcmBytes) {
    const sampleRate = 16000;
    const channels = 1;
    const bitsPerSample = 16;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataLength = pcmBytes.length;
    final fileLength = 36 + dataLength;
    final bytes = BytesBuilder(copy: false)
      ..add(_ascii('RIFF'))
      ..add(_uint32(fileLength))
      ..add(_ascii('WAVE'))
      ..add(_ascii('fmt '))
      ..add(_uint32(16))
      ..add(_uint16(1))
      ..add(_uint16(channels))
      ..add(_uint32(sampleRate))
      ..add(_uint32(byteRate))
      ..add(_uint16(blockAlign))
      ..add(_uint16(bitsPerSample))
      ..add(_ascii('data'))
      ..add(_uint32(dataLength))
      ..add(pcmBytes);
    return bytes.toBytes();
  }

  Uint8List _ascii(String value) => Uint8List.fromList(value.codeUnits);

  Uint8List _uint16(int value) {
    return Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.little);
  }

  Uint8List _uint32(int value) {
    return Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.little);
  }

  Future<void> _sendFileMessage() async {
    if (_isSendingFile) {
      return;
    }
    final app = AppScope.read(context);
    final messages = app.repositories.messages;
    final FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(withData: true);
    } catch (error) {
      if (mounted) {
        _showError(error);
      }
      return;
    }
    if (!mounted) {
      return;
    }
    if (result == null || result.files.isEmpty) {
      return;
    }
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showError('تعذر قراءة الملف المحدد الآن');
      return;
    }
    final fileUrl =
        'data:${_mimeTypeForFile(file.name)};base64,${base64Encode(bytes)}';
    final optimistic = _optimisticMessage(
      text: '${file.name}\n$fileUrl',
      type: _messageTypeForAttachment(file.name, fileUrl),
    );
    setState(() {
      _isSendingFile = true;
      _optimisticMessages.add(optimistic);
    });
    app.notifyMessageStateChanged();
    _scrollToLatest();
    try {
      await messages.sendFileMessage(
        conversationId: widget.contact.conversationId,
        fileName: file.name,
        fileUrl: fileUrl,
      );
      if (!mounted) {
        return;
      }
      _refreshMessagesAfterSend(optimistic.id);
      _scrollToLatest();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _optimisticMessages.removeWhere(
          (message) => message.id == optimistic.id,
        );
      });
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
    if (mounted) {
      AppScope.read(context).notifyMessageStateChanged();
    }
  }

  ChatMessage _optimisticMessage({required String text, required String type}) {
    return ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      text: text,
      incoming: false,
      createdAt: DateTime.now(),
      type: type,
    );
  }

  void _refreshMessagesAfterSend(String completedOptimisticId) {
    final messages = AppScope.read(context).repositories.messages;
    final refreshed = messages
        .fetchMessages(widget.contact.conversationId, forceRefresh: true)
        .then((items) {
          if (mounted) {
            setState(() {
              _optimisticMessages.removeWhere(
                (message) => message.id == completedOptimisticId,
              );
            });
            AppScope.read(context).notifyMessageStateChanged();
          }
          return items;
        });
    setState(() {
      _messagesFuture = refreshed;
    });
  }

  String _messageTypeForAttachment(String fileName, String url) {
    final lower = '$fileName $url'.toLowerCase();
    if (lower.startsWith('data:image/') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif')) {
      return 'image';
    }
    if (lower.startsWith('data:video/') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m4v')) {
      return 'video';
    }
    return 'file';
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          userErrorMessage(error, fallback: 'تعذر تنفيذ العملية الآن'),
        ),
      ),
    );
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
                      !snapshot.hasData &&
                      _optimisticMessages.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = [
                    ...(snapshot.data ?? const <ChatMessage>[]),
                    ..._optimisticMessages,
                  ];
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
                    onPressed: _isSendingVoice ? null : _toggleVoiceRecording,
                    icon: _isSendingVoice
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isRecordingVoice
                                ? Icons.stop_circle_outlined
                                : Icons.mic_none_outlined,
                            color: _isRecordingVoice
                                ? Colors.redAccent
                                : AppColors.blue,
                          ),
                    tooltip: _isRecordingVoice
                        ? 'إيقاف وإرسال التسجيل'
                        : 'رسالة صوتية',
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
                ? _VoiceBubble(text: text, incoming: incoming)
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

class _VoiceBubble extends StatefulWidget {
  const _VoiceBubble({required this.text, required this.incoming});

  final String text;
  final bool incoming;

  @override
  State<_VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<_VoiceBubble> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<void>? _completeSubscription;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _stateSubscription = _player.onPlayerStateChanged.listen((state) {
      if (!mounted) {
        return;
      }
      setState(() => _isPlaying = state == PlayerState.playing);
    });
    _durationSubscription = _player.onDurationChanged.listen((duration) {
      if (!mounted) {
        return;
      }
      setState(() => _duration = duration);
    });
    _positionSubscription = _player.onPositionChanged.listen((position) {
      if (!mounted) {
        return;
      }
      setState(() => _position = position);
    });
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _VoiceBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _player.stop();
      _position = Duration.zero;
      _duration = Duration.zero;
      _isPlaying = false;
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _completeSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isLoading) {
      return;
    }
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_duration > Duration.zero && _position >= _duration) {
        await _player.seek(Duration.zero);
      }
      await _player.play(_sourceFrom(widget.text));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تشغيل الرسالة الصوتية الآن')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Source _sourceFrom(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('data:')) {
      final comma = trimmed.indexOf(',');
      if (comma == -1) {
        throw const FormatException('Invalid audio data URL');
      }
      final header = trimmed.substring(5, comma);
      final mimeType = header.split(';').first;
      return BytesSource(
        base64Decode(trimmed.substring(comma + 1)),
        mimeType: mimeType.isEmpty ? 'audio/wav' : mimeType,
      );
    }
    return UrlSource(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final foreground = widget.incoming ? context.appText : Colors.white;
    final accent = widget.incoming ? AppColors.blue : Colors.white;
    final progress = _duration.inMilliseconds <= 0
        ? 0.0
        : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: _togglePlayback,
      child: SizedBox(
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 34,
                  height: 34,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: _togglePlayback,
                    icon: _isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accent,
                            ),
                          )
                        : Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: accent,
                          ),
                    tooltip: _isPlaying
                        ? 'إيقاف الرسالة الصوتية'
                        : 'تشغيل الرسالة الصوتية',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'رسالة صوتية',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _duration == Duration.zero
                      ? _formatDuration(_position)
                      : '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                  style: TextStyle(
                    color: foreground.withValues(alpha: .82),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 4,
                value: progress,
                backgroundColor: accent.withValues(alpha: .20),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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
