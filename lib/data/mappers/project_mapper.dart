import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/project_item.dart';
import 'supabase_enum_mapper.dart';

ProjectItem projectFromSupabase(
  Map<String, dynamic> row, {
  int colorIndex = 0,
}) {
  final details = _firstMap(row['project_details']);
  final profile = _firstMap(row['profiles']);
  final skills = _stringList(details?['required_skills']);
  final budgetText = _budgetText(row, details);

  return ProjectItem(
    id: '${row['id']}',
    title: '${row['title'] ?? 'مشروع بدون عنوان'}',
    tagline:
        '${details?['tagline'] ?? row['description'] ?? 'مشروع هندسي متاح للتعاون.'}',
    category: '${details?['category'] ?? 'مدني'}',
    type: '${details?['project_type'] ?? 'تعاون مشروع'}',
    workMode: '${details?['work_mode'] ?? 'موقعي'}',
    location: governorateFromSupabase('${row['governorate'] ?? ''}'),
    stage: '${details?['stage'] ?? row['status'] ?? 'تخطيط'}',
    skills: skills.isEmpty ? const ['تنسيق موقع'] : skills,
    commitment: '${details?['weekly_commitment'] ?? '10-20 ساعة'}',
    budget: budgetText,
    postedBy:
        '${profile?['full_name'] ?? details?['company_name'] ?? 'جهة ناشرة'}',
    color: _colorForIndex(colorIndex),
  );
}

Map<String, dynamic> projectInsertPayload({
  required String profileId,
  required String title,
  required String description,
  required String governorate,
  num? budgetMin,
  num? budgetMax,
  DateTime? startDate,
  DateTime? endDate,
  String? imageUrl,
}) {
  final payload = <String, dynamic>{
    'profile_id': profileId,
    'title': title,
    'description': description,
    'governorate': governorateToSupabase(governorate),
    'budget_min': budgetMin,
    'budget_max': budgetMax,
    'status': 'planning',
  };
  if (startDate != null) {
    payload['start_date'] = startDate.toIso8601String();
  }
  if (endDate != null) {
    payload['end_date'] = endDate.toIso8601String();
  }
  if (imageUrl != null) {
    payload['image_url'] = imageUrl;
  }
  return payload;
}

Map<String, dynamic>? _firstMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is List &&
      value.isNotEmpty &&
      value.first is Map<String, dynamic>) {
    return value.first as Map<String, dynamic>;
  }
  return null;
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return [for (final item in value) '$item'];
  }
  if (value is String && value.trim().isNotEmpty) {
    return value.split(',').map((item) => item.trim()).toList();
  }
  return const [];
}

String _budgetText(Map<String, dynamic> row, Map<String, dynamic>? details) {
  final model = details?['payment_model'] ?? 'مدفوع';
  final min = row['budget_min'];
  final max = row['budget_max'];
  if (min == null && max == null) {
    return '$model · حسب الاتفاق';
  }
  if (min != null && max != null) {
    return '$model · $min-$max د.ع';
  }
  return '$model · ${min ?? max} د.ع';
}

Color _colorForIndex(int index) {
  return switch (index % 4) {
    0 => AppColors.blue,
    1 => AppColors.darkBlue,
    2 => AppColors.muted,
    _ => Colors.black,
  };
}
