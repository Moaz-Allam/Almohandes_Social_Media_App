import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/engineer_ai_message.dart';
import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';

class EngineerAiChatScreen extends StatefulWidget {
  const EngineerAiChatScreen({super.key});

  @override
  State<EngineerAiChatScreen> createState() => _EngineerAiChatScreenState();
}

class _EngineerAiChatScreenState extends State<EngineerAiChatScreen> {
  static const _avatarAsset = 'assets/premium/engee_avatar.jpeg';

  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  final _scrollController = ScrollController();
  final List<EngineerAiMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isInputActive = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_updateInputActiveState);
    _inputFocusNode.addListener(_updateInputActiveState);
    _loadMessages();
  }

  @override
  void dispose() {
    _inputController.removeListener(_updateInputActiveState);
    _inputFocusNode.removeListener(_updateInputActiveState);
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateInputActiveState() {
    final nextValue =
        _inputFocusNode.hasFocus || _inputController.text.trim().isNotEmpty;
    if (_isInputActive == nextValue) {
      return;
    }
    setState(() {
      _isInputActive = nextValue;
    });
  }

  Future<void> _loadMessages() async {
    final messages = await AppScope.read(
      context,
    ).repositories.engineerAi.fetchMessages();
    if (!mounted) {
      return;
    }
    setState(() {
      _messages
        ..clear()
        ..addAll(messages);
      _isLoading = false;
    });
    _scrollToBottom();
  }

  Future<void> _sendMessage([String? override]) async {
    if (_isSending) {
      return;
    }
    final content = (override ?? _inputController.text).trim();
    if (content.isEmpty) {
      return;
    }
    _inputController.clear();
    final optimistic = EngineerAiMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      role: EngineerAiRole.user,
      content: content,
      createdAt: DateTime.now(),
    );
    setState(() {
      _messages.add(optimistic);
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final assistantMessage = await AppScope.read(
        context,
      ).repositories.engineerAi.sendMessage(content);
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.add(assistantMessage);
        _isSending = false;
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _messages.removeWhere((message) => message.id == optimistic.id);
        _isSending = false;
      });
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              userErrorMessage(
                error,
                fallback: 'تعذر إرسال الرسالة إلى إنجي الآن',
              ),
            ),
          ),
        );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: context.appBackground,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                _avatarAsset,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'المهندسة إنجي',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'مساعدتك الذكية للاستشارات',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _EmptyEngineerAiChat(
                    showSuggestions: !_isInputActive,
                    onPrompt: _sendMessage,
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isSending && index == _messages.length) {
                        return const _TypingBubble();
                      }
                      return _MessageBubble(
                        message: _messages[index],
                        avatarAsset: _avatarAsset,
                      );
                    },
                  ),
          ),
          _ChatInput(
            controller: _inputController,
            focusNode: _inputFocusNode,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _EmptyEngineerAiChat extends StatelessWidget {
  const _EmptyEngineerAiChat({
    required this.showSuggestions,
    required this.onPrompt,
  });

  final bool showSuggestions;
  final ValueChanged<String> onPrompt;

  @override
  Widget build(BuildContext context) {
    final prompts = const [
      'كيف أراجع مقايسة مشروع؟',
      'اشرح خطوات استلام الخرسانة',
      'ما أهم بنود عقد التنفيذ؟',
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/premium/engee_avatar.jpeg',
                width: 92,
                height: 92,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'المهندسة إنجي',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: showSuggestions
                  ? Padding(
                      key: const ValueKey('engineer-ai-prompts'),
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final prompt in prompts)
                            ActionChip(
                              label: Text(prompt),
                              onPressed: () => onPrompt(prompt),
                              side: BorderSide(color: context.appBorder),
                            ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(
                      key: ValueKey('engineer-ai-prompts-hidden'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.avatarAsset});

  final EngineerAiMessage message;
  final String avatarAsset;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: TextDirection.ltr,
        children: [
          if (!isUser) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                avatarAsset,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 560),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? AppColors.blue : context.appSurfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: isUser ? null : Border.all(color: context.appBorder),
              ),
              child: Text(
                message.content,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: isUser ? AppColors.white : context.appText,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.appSurfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.appBorder),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.focusNode,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: context.appSurface,
          border: Border(top: BorderSide(color: context.appBorder)),
        ),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            IconButton.filled(
              onPressed: isSending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: isSending ? AppColors.muted : AppColors.blue,
                foregroundColor: AppColors.white,
              ),
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(Icons.send),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 104),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 3,
                  textDirection: TextDirection.rtl,
                  keyboardType: TextInputType.multiline,
                  onSubmitted: (_) {
                    if (!isSending) {
                      onSend();
                    }
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    hintText: 'اكتب رسالتك',
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(maxHeight: 104),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
