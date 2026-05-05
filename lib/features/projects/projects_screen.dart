import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
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
      title: 'تنفيذ هيكل مدرسة في بغداد',
      tagline: 'تكوين فريق هندسي وحرفي لتنفيذ الهيكل الخرساني خلال 10 أسابيع.',
      category: 'مدني',
      type: 'تعاون مشروع',
      workMode: 'موقعي',
      location: 'بغداد',
      stage: 'تنفيذ',
      skills: ['إشراف مدني', 'حدادة', 'نجارة قوالب'],
      commitment: '20 ساعة أسبوعيا',
      budget: 'مدفوع · 4-6 مليون د.ع',
      postedBy: 'شركة الرافدين للبناء',
      color: AppColors.blue,
    ),
    ProjectItem(
      id: 'embedded-sensor-cloud',
      title: 'تجهيز كهرباء لمجمع تجاري',
      tagline:
          'تنفيذ تمديدات كهربائية ولوحات توزيع مع فريق سلامة ومراجعة مخططات.',
      category: 'كهرباء',
      type: 'دوام جزئي',
      workMode: 'هجين',
      location: 'البصرة',
      stage: 'تجهيز',
      skills: ['كهرباء مواقع', 'قراءة مخططات', 'سلامة'],
      commitment: '10-20 ساعة',
      budget: 'مدفوع · ثابت',
      postedBy: 'شركة دجلة للمقاولات',
      color: AppColors.darkBlue,
    ),
    ProjectItem(
      id: 'ux-research-kit',
      title: 'تصميم واجهات سكنية حديثة',
      tagline: 'تعاون بين معماري ومهندس إنشائي لإخراج نموذج قابل للتنفيذ.',
      category: 'معماري',
      type: 'بحث وتطوير',
      workMode: 'عن بعد',
      location: 'عن بعد',
      stage: 'فكرة',
      skills: ['تصميم معماري', 'BIM', 'تنسيق إنشائي'],
      commitment: '<10 ساعات',
      budget: 'غير مدفوع · بناء ملف أعمال',
      postedBy: 'مكتب بغداد الهندسي',
      color: AppColors.muted,
    ),
    ProjectItem(
      id: 'secure-devops-lab',
      title: 'تجهيز معدات لموقع طرق',
      tagline: 'توفير شفل وكرين ومشغلين مع جدول تشغيل واضح لمشروع طرق.',
      category: 'آليات',
      type: 'تعاون مقاولين',
      workMode: 'موقعي',
      location: 'أربيل',
      stage: 'توسعة',
      skills: ['تشغيل آليات', 'سلامة معدات', 'تنسيق موقع'],
      commitment: 'دوام كامل',
      budget: 'مدفوع · حسب الساعة',
      postedBy: 'معدات العراق',
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
          decoration: BoxDecoration(
            color: context.appSurface,
            border: Border(bottom: BorderSide(color: context.appBorder)),
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
                    'مدني',
                    'معماري',
                    'كهرباء',
                    'ميكانيك',
                    'آليات',
                    'تشطيبات',
                    'سلامة',
                  ],
                  onSelected: (value) => setState(() => _category = value),
                ),
                _FilterMenu(
                  label: 'نوع المشروع',
                  value: _type,
                  values: const [
                    'كل الأنواع',
                    'تعاون مشروع',
                    'دوام جزئي',
                    'دوام كامل',
                    'بحث وتطوير',
                    'تعاون مقاولين',
                  ],
                  onSelected: (value) => setState(() => _type = value),
                ),
                _FilterMenu(
                  label: 'نمط العمل',
                  value: _workMode,
                  values: const ['كل الأنماط', 'عن بعد', 'هجين', 'موقعي'],
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
            color: context.appSurfaceAlt,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: context.appBorder),
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
