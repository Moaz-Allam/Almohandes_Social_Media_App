import 'package:flutter/material.dart';

final class NotificationItemModel {
  const NotificationItemModel({
    required this.title,
    required this.preview,
    required this.time,
    required this.unread,
    required this.color,
  });

  final String title;
  final String preview;
  final String time;
  final bool unread;
  final Color color;
}
