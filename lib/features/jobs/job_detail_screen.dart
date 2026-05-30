import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/detail_section.dart';
import 'job_application_screen.dart';

/// Read-only detail page for a job posting. Shows everything the creator filled
/// in (description, requirements, type, category, salary, location) and pins a
/// single apply action at the bottom. Opened from the feed job card.
///
/// Pops with `true` once the viewer successfully applies so the feed can
/// refresh its applied-state and toast.
class JobDetailScreen extends StatefulWidget {
  const JobDetailScreen({
    super.key,
    required this.job,
    required this.isOwn,
    required this.didApply,
  });

  /// Raw job row from `jobs` (with embedded `profiles`).
  final Map<String, dynamic> job;
  final bool isOwn;
  final bool didApply;

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  late bool _didApply = widget.didApply;

  Map<String, dynamic> get _job => widget.job;

  String _str(String key) => '${_job[key] ?? ''}'.trim();

  Map<String, dynamic>? get _profiles {
    final value = _job['profiles'];
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }

  String get _companyName {
    final fromRow = _str('company_name');
    if (fromRow.isNotEmpty) {
      return fromRow;
    }
    final embedded = '${_profiles?['full_name'] ?? ''}'.trim();
    return embedded.isEmpty ? 'شركة' : embedded;
  }

  String get _postedBy {
    final name = '${_profiles?['full_name'] ?? ''}'.trim();
    return name.isEmpty ? _companyName : name;
  }

  String _jobTypeLabel(String raw) {
    return switch (raw) {
      'full-time' => 'دوام كامل',
      'part-time' => 'دوام جزئي',
      'contract' => 'عقد',
      'freelance' => 'عمل حر',
      'internship' => 'تدريب',
      _ => raw,
    };
  }

  Future<void> _apply() async {
    final applied = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => JobApplicationScreen(job: _job),
      ),
    );
    if (!mounted) {
      return;
    }
    if (applied == true) {
      setState(() => _didApply = true);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _str('title').isEmpty ? 'وظيفة' : _str('title');
    final location = _str('location');
    final jobType = _jobTypeLabel(_str('job_type'));
    final category = _str('category');
    final salary = _str('salary_range');
    final description = _str('description');
    final requirements = _str('requirements');

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appText,
        title: const Text(
          'تفاصيل الوظيفة',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _Header(
            title: title,
            company: _companyName,
            location: location,
            postedBy: _postedBy,
            avatarUrl: '${_profiles?['avatar_url'] ?? ''}'.isEmpty
                ? null
                : '${_profiles?['avatar_url']}',
          ),
          const SizedBox(height: 12),
          if (jobType.isNotEmpty || category.isNotEmpty || salary.isNotEmpty)
            DetailSection(
              title: 'تفاصيل الوظيفة',
              icon: Icons.work_outline_rounded,
              child: Column(
                children: [
                  if (jobType.isNotEmpty)
                    DetailKeyValue(label: 'نوع العمل', value: jobType),
                  if (category.isNotEmpty)
                    DetailKeyValue(label: 'التصنيف', value: category),
                  if (salary.isNotEmpty)
                    DetailKeyValue(label: 'الراتب المتوقع', value: salary),
                  if (location.isNotEmpty)
                    DetailKeyValue(label: 'الموقع', value: location),
                ],
              ),
            ),
          if (description.isNotEmpty)
            DetailSection(
              title: 'وصف الوظيفة',
              icon: Icons.description_outlined,
              child: DetailParagraph(text: description),
            ),
          if (requirements.isNotEmpty)
            DetailSection(
              title: 'المتطلبات',
              icon: Icons.checklist_rtl_outlined,
              child: DetailParagraph(text: requirements),
            ),
        ],
      ),
      bottomNavigationBar: DetailBottomBar(
        child: _buildAction(),
      ),
    );
  }

  Widget _buildAction() {
    if (widget.isOwn) {
      return const DetailActionButton(label: 'هذه وظيفتك', onPressed: null);
    }
    if (_didApply) {
      return const DetailActionButton(label: 'تم التقديم', onPressed: null);
    }
    return DetailActionButton(
      label: 'تقديم الآن',
      icon: Icons.send_outlined,
      onPressed: _apply,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.company,
    required this.location,
    required this.postedBy,
    required this.avatarUrl,
  });

  final String title;
  final String company;
  final String location;
  final String postedBy;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      company,
      if (location.isNotEmpty) location,
    ].where((value) => value.isNotEmpty).join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.work_outline_rounded,
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(color: context.appMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: context.appBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              AppAvatar(
                name: postedBy,
                radius: 16,
                color: AppColors.blue,
                imageUrl: avatarUrl,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'نشرها $postedBy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
