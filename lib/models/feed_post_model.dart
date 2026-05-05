import 'package:flutter/material.dart';

final class FeedPostModel {
  const FeedPostModel({
    required this.name,
    required this.headline,
    required this.time,
    required this.body,
    required this.reactions,
    required this.comments,
    required this.avatarColor,
    required this.showMedia,
  });

  final String name;
  final String headline;
  final String time;
  final String body;
  final String reactions;
  final String comments;
  final Color avatarColor;
  final bool showMedia;
}
