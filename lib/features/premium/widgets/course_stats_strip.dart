import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/premium_course.dart';

class CourseStatsStrip extends StatelessWidget {
  const CourseStatsStrip({super.key, required this.courses});

  final List<PremiumCourse> courses;

  @override
  Widget build(BuildContext context) {
    final totalLessons = courses.fold<int>(
      0,
      (total, course) => total + course.lessonCount,
    );
    final averageProgress =
        courses.fold<double>(0, (total, course) => total + course.progress) /
        courses.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkBlue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _StatCell(label: 'الدورات', value: '${courses.length}'),
          _Divider(),
          _StatCell(label: 'الفيديوهات', value: '$totalLessons'),
          _Divider(),
          _StatCell(
            label: 'متوسط التقدم',
            value: '${(averageProgress * 100).round()}%',
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.soft, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 42, color: Colors.white24);
  }
}
