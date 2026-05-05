import 'package:flutter/material.dart';

final class ProjectItem {
  const ProjectItem({
    required this.id,
    required this.title,
    required this.tagline,
    required this.category,
    required this.type,
    required this.workMode,
    required this.location,
    required this.stage,
    required this.skills,
    required this.commitment,
    required this.budget,
    required this.postedBy,
    required this.color,
  });

  final String id;
  final String title;
  final String tagline;
  final String category;
  final String type;
  final String workMode;
  final String location;
  final String stage;
  final List<String> skills;
  final String commitment;
  final String budget;
  final String postedBy;
  final Color color;
}
