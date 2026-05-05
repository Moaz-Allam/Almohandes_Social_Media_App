import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/premium_course.dart';

class CourseProgressCard extends StatelessWidget {
  const CourseProgressCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  final PremiumCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percentage = (course.progress * 100).round();

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.appBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: course.color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(course.icon, color: course.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        course.instructor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.appMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: context.appMuted),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              course.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appMuted, height: 1.35),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: course.progress,
                minHeight: 7,
                backgroundColor: context.appSurfaceAlt,
                valueColor: AlwaysStoppedAnimation<Color>(course.color),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$percentage% مكتمل',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                Text(
                  '${course.lessonCount} فيديو',
                  style: TextStyle(color: context.appMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
