import 'package:flutter/material.dart';

final class NotificationItemModel {
  const NotificationItemModel({
    required this.id,
    required this.title,
    required this.preview,
    required this.time,
    required this.type,
    required this.unread,
    required this.color,
    this.actionUrl,
  });

  final String id;
  final String title;
  final String preview;
  final String time;
  final String type;
  final bool unread;
  final Color color;
  final String? actionUrl;

  NotificationItemModel copyWith({
    String? id,
    String? title,
    String? preview,
    String? time,
    String? type,
    bool? unread,
    Color? color,
    String? actionUrl,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      preview: preview ?? this.preview,
      time: time ?? this.time,
      type: type ?? this.type,
      unread: unread ?? this.unread,
      color: color ?? this.color,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}
