import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'models/premium_course.dart';
import 'premium_course_screen.dart';
import 'widgets/course_progress_card.dart';

class PremiumCourseLibraryScreen extends StatelessWidget {
  const PremiumCourseLibraryScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.courses,
    required this.emptyTitle,
  });

  final String title;
  final String subtitle;
  final List<PremiumCourse> courses;
  final String emptyTitle;

  void _openCourse(BuildContext context, PremiumCourse course) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PremiumCourseScreen(course: course)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: courses.isEmpty
          ? _PremiumLibraryEmptyState(title: emptyTitle, subtitle: subtitle)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(
                  subtitle,
                  style: TextStyle(color: context.appMuted, height: 1.45),
                ),
                const SizedBox(height: 14),
                for (final course in courses) ...[
                  CourseProgressCard(
                    course: course,
                    onTap: () => _openCourse(context, course),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
    );
  }
}

class _PremiumLibraryEmptyState extends StatelessWidget {
  const _PremiumLibraryEmptyState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.video_library, color: AppColors.blue),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appMuted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
