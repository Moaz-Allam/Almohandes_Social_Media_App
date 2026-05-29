import 'package:flutter/material.dart';

import 'post_visibility.dart';

final class FeedPostModel {
  const FeedPostModel({
    this.id = '',
    this.profileId,
    required this.name,
    required this.headline,
    required this.time,
    this.location = '',
    required this.body,
    required this.reactions,
    required this.comments,
    required this.avatarColor,
    required this.showMedia,
    this.mediaUrl = '',
    this.mediaType = 'text',
    this.avatarUrl,
    this.isRepost = false,
    this.repostOriginalName,
    this.repostOriginalProfileId,
    this.isLikedByViewer = false,
    this.visibility = PostVisibility.public,
  });

  final String id;
  final String? profileId;
  final String name;
  final String headline;
  final String time;
  final String location;
  final String body;
  final String reactions;
  final String comments;
  final Color avatarColor;
  final bool showMedia;
  final String mediaUrl;
  final String mediaType;
  final String? avatarUrl;
  final bool isRepost;
  final String? repostOriginalName;
  final String? repostOriginalProfileId;
  final bool isLikedByViewer;
  final PostVisibility visibility;

  bool get isReel => mediaType == 'reel' || mediaType == 'video';
  bool get isImagePost => mediaType == 'image';
  bool get isTextOnly => !showMedia && body.trim().isNotEmpty;
  bool get isConnectionsOnly => visibility == PostVisibility.private;
}
