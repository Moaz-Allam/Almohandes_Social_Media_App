import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/skeleton.dart';
import '../home/widgets/home_top_bar.dart';
import 'project_application_screen.dart';
import 'widgets/project_card.dart';
import '../../models/project_item.dart';
import '../../state/app_scope.dart';

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
  late Future<List<ProjectItem>> _projectsFuture;
  bool _didStartLoading = false;

  @override
  void initState() {
    super.initState();
    _projectsFuture = Future.value(const <ProjectItem>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartLoading) {
      return;
    }
    _didStartLoading = true;
    _projectsFuture = AppScope.read(
      context,
    ).repositories.projects.fetchProjects();
  }

  List<ProjectItem> _visibleProjects(List<ProjectItem> projects) {
    final filtered = projects.where((project) {
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
          child: FutureBuilder<List<ProjectItem>>(
            future: _projectsFuture,
            builder: (context, snapshot) {
              final projects = _visibleProjects(
                snapshot.data ?? const <ProjectItem>[],
              );
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const _ProjectsSkeletonList();
              }
              if (projects.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد مشاريع بهذه الفلاتر.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _projectsFuture = AppScope.read(
                      context,
                    ).repositories.projects.fetchProjects(forceRefresh: true);
                  });
                  await _projectsFuture;
                },
                child: ListView.builder(
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

class _ProjectsSkeletonList extends StatelessWidget {
  const _ProjectsSkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: const [
        ProjectCardSkeleton(),
        ProjectCardSkeleton(),
        ProjectCardSkeleton(),
      ],
    );
  }
}
