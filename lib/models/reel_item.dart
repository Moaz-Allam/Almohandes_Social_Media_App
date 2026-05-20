import 'package:flutter/material.dart';

final class ReelItem {
  const ReelItem({
    required this.id,
    required this.profileId,
    required this.name,
    required this.headline,
    required this.caption,
    required this.likesCount,
    required this.commentsCount,
    required this.repostsCount,
    required this.color,
    this.videoUrl,
    this.thumbnailUrl,
    this.avatarUrl,
    this.createdAt,
  });

  final String id;
  final String profileId;
  final String name;
  final String headline;
  final String caption;
  final int likesCount;
  final int commentsCount;
  final int repostsCount;
  final Color color;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? avatarUrl;
  final DateTime? createdAt;

  String get likesLabel => _compactCount(likesCount);
  String get commentsLabel => _compactCount(commentsCount);
  String get repostsLabel => _compactCount(repostsCount);
}

String _compactCount(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(value % 1000000 == 0 ? 0 : 1)}M';
  }
  if (value >= 1000) {
    return '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
  }
  return '$value';
}
