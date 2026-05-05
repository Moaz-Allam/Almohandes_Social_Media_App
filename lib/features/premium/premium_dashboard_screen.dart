import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'data/premium_courses.dart';
import 'models/premium_course.dart';
import 'premium_course_screen.dart';
import 'widgets/course_progress_card.dart';
import 'widgets/course_stats_strip.dart';

class PremiumDashboardScreen extends StatelessWidget {
  const PremiumDashboardScreen({super.key});

  void _openCourse(BuildContext context, PremiumCourse course) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PremiumCourseScreen(course: course)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appSoft,
      appBar: AppBar(
        title: const Text('لوحة Premium'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          const Text(
            'مكتبة الدورات',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'تابع تقدمك في دورات هندسية عملية وافتح كل دورة لمشاهدة قوائم التشغيل والفيديوهات.',
            style: TextStyle(color: context.appMuted, height: 1.45),
          ),
          const SizedBox(height: 16),
          const CourseStatsStrip(courses: premiumCourses),
          const SizedBox(height: 16),
          for (final course in premiumCourses) ...[
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
