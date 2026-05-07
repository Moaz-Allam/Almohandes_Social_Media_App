import 'package:flutter/material.dart';

final class StoryItem {
  const StoryItem({
    required this.id,
    required this.name,
    required this.color,
    this.isNew = false,
    this.content = '',
    this.mediaUrl = '',
  });

  final String id;
  final String name;
  final Color color;
  final bool isNew;
  final String content;
  final String mediaUrl;
}
