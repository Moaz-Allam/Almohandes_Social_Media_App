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
  });

  final String conversationId;
  final String? profileId;
  final String name;
  final String preview;
  final String time;
  final bool unread;
  final Color color;
}

final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.incoming,
    required this.createdAt,
  });

  final String id;
  final String text;
  final bool incoming;
  final DateTime createdAt;
}
