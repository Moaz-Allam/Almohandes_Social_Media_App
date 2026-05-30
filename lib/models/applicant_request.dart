import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

/// A single applicant on a listing the owner created (project or job). Used by
/// the owner's applicants screen, where each can be viewed and matched.
final class ApplicantRequest {
  const ApplicantRequest({
    required this.applicationId,
    required this.profileId,
    required this.name,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.color,
    this.avatarUrl,
  });

  final String applicationId;
  final String profileId;
  final String name;
  final String title;
  final String message;
  final String status;
  final DateTime createdAt;
  final Color color;
  final String? avatarUrl;

  bool get isAccepted => status == 'accepted';

  /// Builds from a `get_job_applications` RPC row.
  static ApplicantRequest job(Map<String, dynamic> row, int index) {
    final name = '${row['full_name'] ?? ''}'.trim();
    final title = '${row['bio'] ?? row['role'] ?? ''}'.trim();
    return ApplicantRequest(
      applicationId: '${row['application_id'] ?? ''}',
      profileId: '${row['applicant_id'] ?? ''}',
      name: name.isEmpty ? 'مستخدم' : name,
      title: title.isEmpty ? 'طلب تقديم' : title,
      message: '${row['cover_letter'] ?? ''}',
      status: '${row['status'] ?? 'pending'}',
      createdAt:
          DateTime.tryParse('${row['created_at']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      color: _colorForIndex(index),
      avatarUrl: row['avatar_url'] == null ? null : '${row['avatar_url']}',
    );
  }

  static Color _colorForIndex(int index) {
    return switch (index % 4) {
      0 => AppColors.blue,
      1 => AppColors.darkBlue,
      2 => AppColors.muted,
      _ => AppColors.black,
    };
  }
}
