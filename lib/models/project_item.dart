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
    this.profileId,
    this.creatorAvatarUrl,
    this.hasApplied = false,
    this.description = '',
    this.details = const <String, dynamic>{},
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
  final String? profileId;
  final String? creatorAvatarUrl;
  final bool hasApplied;

  /// Full project description (the `projects.description` column).
  final String description;

  /// Raw `project_details` row (the rich brief the creator filled in:
  /// problem, goals, roles, responsibilities, milestones, budget, etc.).
  /// Empty when the project has no details row. Used by the detail page.
  final Map<String, dynamic> details;

  ProjectItem copyWith({bool? hasApplied}) {
    return ProjectItem(
      id: id,
      title: title,
      tagline: tagline,
      category: category,
      type: type,
      workMode: workMode,
      location: location,
      stage: stage,
      skills: skills,
      commitment: commitment,
      budget: budget,
      postedBy: postedBy,
      color: color,
      profileId: profileId,
      creatorAvatarUrl: creatorAvatarUrl,
      hasApplied: hasApplied ?? this.hasApplied,
      description: description,
      details: details,
    );
  }
}
