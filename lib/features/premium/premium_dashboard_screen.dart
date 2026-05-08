import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/app_scope.dart';
import 'models/premium_course.dart';
import 'premium_access_screen.dart';
import 'premium_course_screen.dart';
import 'widgets/course_progress_card.dart';
import 'widgets/course_stats_strip.dart';

class PremiumDashboardScreen extends StatefulWidget {
  const PremiumDashboardScreen({super.key});

  @override
  State<PremiumDashboardScreen> createState() => _PremiumDashboardScreenState();
}

class _PremiumDashboardScreenState extends State<PremiumDashboardScreen> {
  late Future<List<PremiumCourse>> _coursesFuture;

  @override
  void initState() {
    super.initState();
    _coursesFuture = Future.value(const <PremiumCourse>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _coursesFuture = AppScope.read(
      context,
    ).repositories.courses.fetchPremiumCourses();
  }

  void _openCourse(BuildContext context, PremiumCourse course) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PremiumCourseScreen(course: course)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!AppScope.watch(context).hasPremiumLibrary) {
      return const PremiumAccessScreen();
    }
    return Scaffold(
      backgroundColor: context.appSoft,
      appBar: AppBar(
        title: const Text('لوحة Premium'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: FutureBuilder<List<PremiumCourse>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final courses = snapshot.data ?? const <PremiumCourse>[];
          if (courses.isEmpty) {
            return const _PremiumCoursesEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _coursesFuture = AppScope.read(
                  context,
                ).repositories.courses.fetchPremiumCourses(forceRefresh: true);
              });
              await _coursesFuture;
            },
            child: ListView(
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
                CourseStatsStrip(courses: courses),
                const SizedBox(height: 16),
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
        },
      ),
    );
  }
}

class _PremiumCoursesEmptyState extends StatelessWidget {
  const _PremiumCoursesEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school_outlined, color: AppColors.muted, size: 48),
            SizedBox(height: 12),
            Text(
              'لا توجد دورات Premium بعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 6),
            Text(
              'ستظهر الدورات هنا بعد إضافتها.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }
}
