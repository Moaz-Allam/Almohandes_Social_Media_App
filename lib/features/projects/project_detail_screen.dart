import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/project_item.dart';
import '../../shared/widgets/app_avatar.dart';
import '../../shared/widgets/detail_section.dart';
import '../../state/app_scope.dart';
import 'project_application_screen.dart';

/// Read-only detail page for a project. Surfaces the full brief the creator
/// filled in (problem, goals, required/preferred skills, roles,
/// responsibilities, milestones, budget, timeline …) and pins a single apply
/// action at the bottom. Opened from the feed project card.
class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({
    super.key,
    required this.project,
    required this.canApply,
  });

  final ProjectItem project;

  /// False when the viewer owns the project (can't apply to their own).
  final bool canApply;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late bool _didApply = widget.project.hasApplied;

  ProjectItem get _project => widget.project;
  Map<String, dynamic> get _details => _project.details;

  String _d(String key) {
    final value = _details[key];
    if (value == null) {
      return '';
    }
    final text = '$value'.trim();
    return text == 'null' ? '' : text;
  }

  List<String> _dList(String key) {
    final value = _details[key];
    if (value is List) {
      return [
        for (final item in value)
          if ('$item'.trim().isNotEmpty) '$item'.trim(),
      ];
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(RegExp(r'[,،\n]'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  String get _responsibilities {
    final value = _details['responsibilities'];
    if (value is Map) {
      return '${value['text'] ?? ''}'.trim();
    }
    final text = '${value ?? ''}'.trim();
    return text == 'null' ? '' : text;
  }

  Future<void> _apply() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProjectApplicationScreen(project: _project),
      ),
    );
    if (!mounted) {
      return;
    }
    // ProjectApplicationScreen replaces itself with the success screen on a
    // successful submit, so re-check the applied set rather than relying on a
    // pop result.
    final appliedIds = await AppScope.read(context)
        .repositories
        .projects
        .fetchAppliedProjectIds(forceRefresh: true);
    if (!mounted) {
      return;
    }
    if (appliedIds.contains(_project.id)) {
      setState(() => _didApply = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final problem = _d('problem');
    final goals = _d('goals');
    final targetUsers = _d('target_users');
    final requiredSkills =
        _project.skills.isNotEmpty ? _project.skills : _dList('required_skills');
    final preferredSkills = _dList('preferred_skills');
    final tools = _dList('tools_equipment');
    final certifications = _dList('certifications');
    final roles = _dList('roles_needed');
    final milestones = _dList('milestones');
    final bonus = _d('bonus_incentives');

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        foregroundColor: context.appText,
        title: const Text(
          'تفاصيل المشروع',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
        children: [
          _Header(project: _project),
          const SizedBox(height: 12),
          if (_project.description.isNotEmpty)
            DetailSection(
              title: 'نظرة عامة',
              icon: Icons.description_outlined,
              child: DetailParagraph(text: _project.description),
            ),
          if (problem.isNotEmpty)
            DetailSection(
              title: 'المشكلة',
              icon: Icons.report_problem_outlined,
              child: DetailParagraph(text: problem),
            ),
          if (goals.isNotEmpty)
            DetailSection(
              title: 'الأهداف',
              icon: Icons.flag_outlined,
              child: DetailParagraph(text: goals),
            ),
          if (targetUsers.isNotEmpty)
            DetailSection(
              title: 'المستخدمون المستهدفون',
              icon: Icons.groups_outlined,
              child: DetailParagraph(text: targetUsers),
            ),
          _buildFacts(),
          if (requiredSkills.isNotEmpty ||
              preferredSkills.isNotEmpty ||
              tools.isNotEmpty ||
              certifications.isNotEmpty)
            DetailSection(
              title: 'المهارات والأدوات',
              icon: Icons.handyman_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (requiredSkills.isNotEmpty) ...[
                    _SubLabel('المهارات المطلوبة'),
                    DetailChips(items: requiredSkills),
                  ],
                  if (preferredSkills.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SubLabel('مهارات مفضلة'),
                    DetailChips(items: preferredSkills),
                  ],
                  if (tools.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SubLabel('الأدوات والمعدات'),
                    DetailChips(items: tools),
                  ],
                  if (certifications.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SubLabel('الشهادات'),
                    DetailChips(items: certifications),
                  ],
                ],
              ),
            ),
          if (roles.isNotEmpty || _responsibilities.isNotEmpty)
            DetailSection(
              title: 'الأدوار والمسؤوليات',
              icon: Icons.assignment_ind_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (roles.isNotEmpty) ...[
                    _SubLabel('الأدوار المطلوبة'),
                    DetailBullets(items: roles),
                  ],
                  if (_responsibilities.isNotEmpty) ...[
                    if (roles.isNotEmpty) const SizedBox(height: 10),
                    _SubLabel('المسؤوليات'),
                    DetailParagraph(text: _responsibilities),
                  ],
                ],
              ),
            ),
          if (milestones.isNotEmpty)
            DetailSection(
              title: 'المراحل الرئيسية',
              icon: Icons.timeline_outlined,
              child: DetailBullets(items: milestones),
            ),
          if (bonus.isNotEmpty)
            DetailSection(
              title: 'حوافز إضافية',
              icon: Icons.card_giftcard_outlined,
              child: DetailParagraph(text: bonus),
            ),
        ],
      ),
      bottomNavigationBar: DetailBottomBar(child: _buildAction()),
    );
  }

  Widget _buildFacts() {
    final facts = <DetailKeyValue>[
      if (_project.category.isNotEmpty)
        DetailKeyValue(label: 'التصنيف', value: _project.category),
      if (_project.type.isNotEmpty)
        DetailKeyValue(label: 'نوع المشروع', value: _project.type),
      if (_project.workMode.isNotEmpty)
        DetailKeyValue(label: 'نمط العمل', value: _project.workMode),
      if (_project.stage.isNotEmpty)
        DetailKeyValue(label: 'المرحلة', value: _project.stage),
      if (_project.location.isNotEmpty)
        DetailKeyValue(label: 'الموقع', value: _project.location),
      if (_d('seniority_level').isNotEmpty)
        DetailKeyValue(label: 'مستوى الخبرة', value: _d('seniority_level')),
      if (_d('years_experience').isNotEmpty && _d('years_experience') != '0')
        DetailKeyValue(
          label: 'سنوات الخبرة',
          value: '${_d('years_experience')} سنوات',
        ),
      if (_d('engineers_needed').isNotEmpty && _d('engineers_needed') != '0')
        DetailKeyValue(
          label: 'عدد المهندسين',
          value: _d('engineers_needed'),
        ),
      if (_project.commitment.isNotEmpty)
        DetailKeyValue(label: 'الالتزام الأسبوعي', value: _project.commitment),
      if (_d('estimated_duration').isNotEmpty)
        DetailKeyValue(label: 'المدة التقديرية', value: _d('estimated_duration')),
      if (_d('deadline_urgency').isNotEmpty)
        DetailKeyValue(label: 'مدى الإلحاح', value: _d('deadline_urgency')),
      if (_d('current_team_size').isNotEmpty)
        DetailKeyValue(label: 'حجم الفريق الحالي', value: _d('current_team_size')),
      if (_project.budget.isNotEmpty)
        DetailKeyValue(label: 'الميزانية', value: _project.budget),
      if (_d('payment_status').isNotEmpty)
        DetailKeyValue(label: 'حالة الدفع', value: _d('payment_status')),
    ];
    if (facts.isEmpty) {
      return const SizedBox.shrink();
    }
    return DetailSection(
      title: 'تفاصيل المشروع',
      icon: Icons.info_outline_rounded,
      child: Column(children: facts),
    );
  }

  Widget _buildAction() {
    if (!widget.canApply) {
      return const DetailActionButton(label: 'هذا مشروعك', onPressed: null);
    }
    if (_didApply) {
      return const DetailActionButton(label: 'تم التقديم', onPressed: null);
    }
    return DetailActionButton(
      label: 'تقديم على المشروع',
      icon: Icons.send_outlined,
      onPressed: _apply,
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: context.appMuted,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.project});

  final ProjectItem project;

  @override
  Widget build(BuildContext context) {
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
                  color: project.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_special_outlined,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                    if (project.tagline.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        project.tagline,
                        style: TextStyle(color: context.appMuted, height: 1.4),
                      ),
                    ],
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
                name: project.postedBy,
                radius: 16,
                color: project.color,
                imageUrl: project.creatorAvatarUrl,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'نشره ${project.postedBy}',
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
