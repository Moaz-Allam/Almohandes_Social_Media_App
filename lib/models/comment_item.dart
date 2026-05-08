import 'package:flutter/material.dart';

final class CommentItem {
  const CommentItem({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.color,
    this.avatarUrl,
  });

  final String id;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final Color color;
  final String? avatarUrl;
}
