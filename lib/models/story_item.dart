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
    this.seen = false,
    this.viewsCount = 0,
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

  /// Whether the current viewer has already opened this story (persisted in
  /// `story_views`), so the strip can render it with a muted "seen" ring.
  final bool seen;

  /// Total unique viewers — only meaningful to the story's creator.
  final int viewsCount;

  StoryItem copyWith({bool? seen, int? viewsCount}) {
    return StoryItem(
      id: id,
      profileId: profileId,
      name: name,
      color: color,
      isNew: isNew,
      content: content,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      avatarUrl: avatarUrl,
      seen: seen ?? this.seen,
      viewsCount: viewsCount ?? this.viewsCount,
    );
  }

  bool get hasVisualMedia =>
      mediaUrl.trim().isNotEmpty &&
      mediaType != 'text' &&
      !mediaUrl.startsWith('text-story:');
  bool get isVideo => mediaType == 'video' || mediaType == 'reel';
}
