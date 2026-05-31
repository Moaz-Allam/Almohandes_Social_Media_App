import 'package:flutter/material.dart';

final class CommentItem {
  const CommentItem({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.color,
    this.authorId,
    this.avatarUrl,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.parentId,
    this.isLikedByViewer = false,
  });

  final String id;

  /// Profile id of the author. Used to decide whether the current viewer can
  /// edit/delete this comment. Null on legacy rows that don't expose it.
  final String? authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final Color color;
  final String? avatarUrl;
  final int likesCount;
  final int repliesCount;
  final String? parentId;
  final bool isLikedByViewer;

  bool get isReply => parentId != null && parentId!.isNotEmpty;

  CommentItem copyWith({
    String? content,
    int? likesCount,
    int? repliesCount,
    bool? isLikedByViewer,
  }) {
    return CommentItem(
      id: id,
      authorId: authorId,
      authorName: authorName,
      content: content ?? this.content,
      createdAt: createdAt,
      color: color,
      avatarUrl: avatarUrl,
      likesCount: likesCount ?? this.likesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      parentId: parentId,
      isLikedByViewer: isLikedByViewer ?? this.isLikedByViewer,
    );
  }
}
