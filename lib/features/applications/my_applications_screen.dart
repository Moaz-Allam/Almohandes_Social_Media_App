import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/my_application.dart';
import '../../state/app_scope.dart';

/// "تقديماتي" — every project and job the current user applied to, with the
/// current status of each application (pending / matched / rejected).
class MyApplicationsScreen extends StatefulWidget {
  const MyApplicationsScreen({super.key});

  @override
  State<MyApplicationsScreen> createState() => _MyApplicationsScreenState();
}

enum _ApplicationsFilter { all, projects, jobs }

class _MyApplicationsScreenState extends State<MyApplicationsScreen> {
  _ApplicationsFilter _filter = _ApplicationsFilter.all;
  late Future<List<MyApplication>> _future;

  @override
  void initState() {
    super.initState();
    _future = Future.value(const <MyApplication>[]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _load();
  }

  Future<List<MyApplication>> _load() async {
    final app = AppScope.read(context);
    final results = await Future.wait<List<MyApplication>>([
      app.repositories.projects.fetchMyProjectApplications(),
      app.repositories.jobs.fetchMyJobApplications(),
    ]);
    final all = [...results[0], ...results[1]]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appText,
        title: const Text(
          'تقديماتي',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: context.appSurface,
              border: Border(bottom: BorderSide(color: context.appBorder)),
            ),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final filter in _ApplicationsFilter.values)
                  _FilterChip(
                    label: _filterLabel(filter),
                    selected: _filter == filter,
                    onTap: () => setState(() => _filter = filter),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MyApplication>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = (snapshot.data ?? const <MyApplication>[])
                    .where(_matchesFilter)
                    .toList();
                if (items.isEmpty) {
                  return _EmptyState(onRefresh: _refresh);
                }
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _ApplicationTile(item: items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matchesFilter(MyApplication item) {
    return switch (_filter) {
      _ApplicationsFilter.all => true,
      _ApplicationsFilter.projects => item.isProject,
      _ApplicationsFilter.jobs => item.isJob,
    };
  }

  String _filterLabel(_ApplicationsFilter filter) {
    return switch (filter) {
      _ApplicationsFilter.all => 'الكل',
      _ApplicationsFilter.projects => 'مشاريع',
      _ApplicationsFilter.jobs => 'وظائف',
    };
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8, top: 8, bottom: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.blue,
        labelStyle: TextStyle(
          color: selected ? AppColors.white : context.appText,
          fontWeight: FontWeight.w800,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.item});

  final MyApplication item;

  @override
  Widget build(BuildContext context) {
    final title = item.title.isEmpty
        ? (item.isProject ? 'مشروع' : 'وظيفة')
        : item.title;
    return Material(
      color: context.appSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: context.appBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: context.appSurfaceAlt,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.isProject
                    ? Icons.folder_special_outlined
                    : Icons.work_outline_rounded,
                color: AppColors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.isProject ? 'مشروع' : 'وظيفة'} · ${item.ownerName}'
                    '${item.subtitle.isEmpty ? '' : ' · ${item.subtitle}'}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.appMuted, height: 1.3),
                  ),
                  const SizedBox(height: 10),
                  _StatusChip(status: item.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _styleFor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _styleFor(String status) {
    return switch (status) {
      'accepted' => ('تمت المطابقة', AppColors.blue, Icons.verified_rounded),
      'rejected' => ('مرفوض', Colors.redAccent, Icons.cancel_outlined),
      'withdrawn' => ('مسحوب', AppColors.muted, Icons.undo_rounded),
      _ => ('قيد المراجعة', Color(0xFFB8860B), Icons.hourglass_top_rounded),
    };
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        children: const [
          SizedBox(height: 120),
          Icon(
            Icons.assignment_outlined,
            color: AppColors.muted,
            size: 46,
          ),
          SizedBox(height: 12),
          Text(
            'لم تقدّم على أي مشروع أو وظيفة بعد',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'عند تقديمك على مشروع أو وظيفة سيظهر هنا مع حالة الطلب',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
