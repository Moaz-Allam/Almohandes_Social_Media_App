import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/project_item.dart';
import '../home/widgets/home_top_bar.dart';
import 'project_application_screen.dart';
import 'widgets/project_card.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({
    super.key,
    required this.onMenu,
    required this.onMessages,
  });

  final VoidCallback onMenu;
  final VoidCallback onMessages;

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _sortBy = 'الأحدث';
  String _category = 'كل الفئات';
  String _type = 'كل الأنواع';
  String _workMode = 'كل الأنماط';

  static const _projects = [
    ProjectItem(
      id: 'ai-career-match',
      title: 'محرك مطابقة مشاريع بالذكاء الاصطناعي',
      tagline: 'ابن نظام توصية يربط المهندسين بالمشاريع المناسبة.',
      category: 'AI/ML',
      type: 'Startup Collaboration',
      workMode: 'Remote',
      location: 'عن بعد',
      stage: 'MVP',
      skills: ['Python', 'NLP', 'Flutter'],
      commitment: '10-20h',
      budget: 'مدفوع · 900-1400 USD',
      postedBy: 'Nile Labs',
      color: AppColors.blue,
    ),
    ProjectItem(
      id: 'embedded-sensor-cloud',
      title: 'منصة مراقبة حساسات صناعية',
      tagline: 'لوحة لحظية تقرأ بيانات أجهزة مدمجة وترسل تنبيهات.',
      category: 'Embedded Systems',
      type: 'Part-time',
      workMode: 'Hybrid',
      location: 'القاهرة',
      stage: 'Production',
      skills: ['C++', 'MQTT', 'Cloud'],
      commitment: '<10h',
      budget: 'مدفوع · ثابت',
      postedBy: 'Delta IoT',
      color: AppColors.darkBlue,
    ),
    ProjectItem(
      id: 'ux-research-kit',
      title: 'حزمة أدوات بحث تجربة مستخدم عربية',
      tagline: 'قوالب ومكونات تساعد الفرق الصغيرة على اختبار منتجاتها.',
      category: 'UI/UX',
      type: 'Research',
      workMode: 'Remote',
      location: 'عن بعد',
      stage: 'Idea',
      skills: ['Figma', 'UX Research', 'Writing'],
      commitment: '<10h',
      budget: 'غير مدفوع · مشاركة معرفة',
      postedBy: 'مصممون عرب',
      color: AppColors.muted,
    ),
    ProjectItem(
      id: 'secure-devops-lab',
      title: 'مختبر DevOps آمن للتدريب',
      tagline: 'بيئة سحابية صغيرة لتعليم النشر والمراقبة بأمان.',
      category: 'Cloud/DevOps',
      type: 'Internship',
      workMode: 'On-site',
      location: 'الجيزة',
      stage: 'Scaling',
      skills: ['Docker', 'CI/CD', 'Security'],
      commitment: '10-20h',
      budget: 'Stipend · EGP',
      postedBy: 'Cloud MENA',
      color: AppColors.black,
    ),
  ];

  List<ProjectItem> get _visibleProjects {
    final filtered = _projects.where((project) {
      final categoryMatches =
          _category == 'كل الفئات' || project.category == _category;
      final typeMatches = _type == 'كل الأنواع' || project.type == _type;
      final modeMatches =
          _workMode == 'كل الأنماط' || project.workMode == _workMode;
      return categoryMatches && typeMatches && modeMatches;
    }).toList();

    if (_sortBy == 'الأعلى ميزانية') {
      filtered.sort((a, b) => b.budget.compareTo(a.budget));
    }
    return filtered;
  }

  void _openApplication(ProjectItem project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectApplicationScreen(project: project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projects = _visibleProjects;

    return Column(
      children: [
        HomeTopBar(
          onMenu: widget.onMenu,
          onMessages: widget.onMessages,
          hint: 'ابحث عن مشروع',
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterMenu(
                  label: 'الترتيب',
                  value: _sortBy,
                  values: const ['الأحدث', 'الأعلى ميزانية'],
                  onSelected: (value) => setState(() => _sortBy = value),
                ),
                _FilterMenu(
                  label: 'الفئة',
                  value: _category,
                  values: const [
                    'كل الفئات',
                    'Web App',
                    'Mobile App',
                    'Embedded Systems',
                    'AI/ML',
                    'Robotics',
                    'Cybersecurity',
                    'UI/UX',
                    'Cloud/DevOps',
                  ],
                  onSelected: (value) => setState(() => _category = value),
                ),
                _FilterMenu(
                  label: 'نوع المشروع',
                  value: _type,
                  values: const [
                    'كل الأنواع',
                    'Freelance',
                    'Internship',
                    'Part-time',
                    'Full-time',
                    'Research',
                    'Startup Collaboration',
                  ],
                  onSelected: (value) => setState(() => _type = value),
                ),
                _FilterMenu(
                  label: 'نمط العمل',
                  value: _workMode,
                  values: const ['كل الأنماط', 'Remote', 'Hybrid', 'On-site'],
                  onSelected: (value) => setState(() => _workMode = value),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: projects.isEmpty
              ? const Center(
                  child: Text(
                    'لا توجد مشاريع بهذه الفلاتر.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return ProjectCard(
                      project: project,
                      onApply: () => _openApplication(project),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.values,
    required this.onSelected,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: PopupMenuButton<String>(
        onSelected: onSelected,
        itemBuilder: (context) => [
          for (final item in values)
            PopupMenuItem(value: item, child: Text(item)),
        ],
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label: $value',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
