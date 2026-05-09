import 'package:flutter/material.dart';

final class MessageItem {
  const MessageItem({
    required this.conversationId,
    this.profileId,
    required this.name,
    required this.preview,
    required this.time,
    required this.unread,
    required this.color,
    this.unreadCount = 0,
    this.avatarUrl,
  });

  final String conversationId;
  final String? profileId;
  final String name;
  final String preview;
  final String time;
  final bool unread;
  final Color color;
  final int unreadCount;
  final String? avatarUrl;
}

final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.incoming,
    required this.createdAt,
    this.type = 'text',
  });

  final String id;
  final String text;
  final bool incoming;
  final DateTime createdAt;
  final String type;

  bool get isVoice => type == 'voice';
  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isFile => type == 'file';
  bool get isShareLink =>
      text.startsWith('app://post/') || text.startsWith('app://reel/');
}
