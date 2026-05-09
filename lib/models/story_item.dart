import 'package:flutter/material.dart';

final class StoryItem {
  const StoryItem({
    required this.id,
    this.profileId = '',
    required this.name,
    required this.color,
    this.isNew = false,
    this.content = '',
    this.mediaUrl = '',
    this.mediaType = 'text',
    this.avatarUrl,
  });

  final String id;
  final String profileId;
  final String name;
  final Color color;
  final bool isNew;
  final String content;
  final String mediaUrl;
  final String mediaType;
  final String? avatarUrl;

  bool get hasVisualMedia =>
      mediaUrl.trim().isNotEmpty &&
      mediaType != 'text' &&
      !mediaUrl.startsWith('text-story:');
  bool get isVideo => mediaType == 'video' || mediaType == 'reel';
}
