import 'package:flutter/material.dart';

final class ProjectApplicationRequest {
  const ProjectApplicationRequest({
    required this.id,
    required this.profileId,
    required this.name,
    required this.title,
    required this.message,
    required this.status,
    required this.attachmentsCount,
    required this.createdAt,
    required this.color,
    this.avatarUrl,
  });

  final String id;
  final String profileId;
  final String name;
  final String title;
  final String message;
  final String status;
  final int attachmentsCount;
  final DateTime createdAt;
  final Color color;
  final String? avatarUrl;
}
