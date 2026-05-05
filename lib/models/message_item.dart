import 'package:flutter/material.dart';

final class MessageItem {
  const MessageItem({
    required this.name,
    required this.preview,
    required this.time,
    required this.unread,
    required this.color,
  });

  final String name;
  final String preview;
  final String time;
  final bool unread;
  final Color color;
}
