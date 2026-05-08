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
  bool _appliedOnly = false;
  late Future<({Set<String> appliedIds, List<ProjectItem> projects})>
  _projectsFuture;
  bool _didStartLoading = false;

  @override
  void initState() {
    super.initState();
    _projectsFuture = Future.value((
      projects: const <ProjectItem>[],
      appliedIds: const <String>{},
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didStartLoading) {
      return;
    }
    _didStartLoading = true;
    _projectsFuture = _loadProjects();
  }

  Future<({Set<String> appliedIds, List<ProjectItem> projects})> _loadProjects({
    bool forceRefresh = false,
  }) async {
    final projects = AppScope.read(
      context,
    ).repositories.projects.fetchProjects(forceRefresh: forceRefresh);
    final appliedIds = AppScope.read(
      context,
    ).repositories.projects.fetchAppliedProjectIds(forceRefresh: forceRefresh);
    final result = await (projects, appliedIds).wait;
    return (projects: result.$1, appliedIds: result.$2);
  }

  List<ProjectItem> _visibleProjects(
    List<ProjectItem> projects,
    Set<String> appliedIds,
  ) {
    final filtered = projects.where((project) {
      if (_appliedOnly && !appliedIds.contains(project.id)) {
        return false;
      }
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

  Future<void> _openApplication(ProjectItem project) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectApplicationScreen(project: project),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _projectsFuture = _loadProjects(forceRefresh: true);
    });
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
                FilterChip(
                  selected: _appliedOnly,
                  onSelected: (value) => setState(() => _appliedOnly = value),
                  label: const Text('قدمت عليها'),
                  avatar: _appliedOnly
                      ? const Icon(Icons.check, size: 16)
                      : null,
                  selectedColor: context.appPaleBlue,
                  checkmarkColor: AppColors.blue,
                  side: BorderSide(
                    color: _appliedOnly ? AppColors.blue : context.appBorder,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child:
              FutureBuilder<
                ({Set<String> appliedIds, List<ProjectItem> projects})
              >(
                future: _projectsFuture,
                builder: (context, snapshot) {
                  final data =
                      snapshot.data ??
                      (
                        projects: const <ProjectItem>[],
                        appliedIds: const <String>{},
                      );
                  final projects = _visibleProjects(
                    data.projects,
                    data.appliedIds,
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
                        _projectsFuture = _loadProjects(forceRefresh: true);
                      });
                      await _projectsFuture;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        final myProfileId = AppScope.watch(context).profile?.id;
                        final didApply = data.appliedIds.contains(project.id);
                        return ProjectCard(
                          project: project.copyWith(hasApplied: didApply),
                          onApply: () => _openApplication(project),
                          canApply:
                              !didApply &&
                              (project.profileId == null ||
                                  project.profileId != myProfileId),
                          actionLabel: didApply
                              ? 'تم التقديم'
                              : (project.profileId == myProfileId
                                    ? 'مشروعك'
                                    : null),
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
