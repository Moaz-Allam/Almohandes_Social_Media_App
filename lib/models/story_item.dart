import 'package:flutter/material.dart';

final class StoryItem {
  const StoryItem({
    required this.name,
    required this.color,
    this.isNew = false,
  });

  final String name;
  final Color color;
  final bool isNew;
}
