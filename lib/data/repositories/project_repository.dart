import 'package:flutter/material.dart' show Color;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../session/current_profile_resolver.dart';

import '../../core/constants/app_colors.dart';
import '../../models/project_application_request.dart';
import '../../models/project_draft.dart';
import '../../models/project_item.dart';
import '../cache/timed_memory_cache.dart';
import '../mappers/project_mapper.dart';
import '../mappers/supabase_enum_mapper.dart';
import 'repository_failure.dart';

abstract interface class ProjectRepository {
  Future<List<ProjectItem>> fetchProjects({bool forceRefresh = false});

  /// Server-side search across projects by title / description. Returns up to
  /// a page of matches; empty when [query] is blank.
  Future<List<ProjectItem>> searchJobs(String query);

  Future<List<ProjectItem>> fetchProjectsForProfile(
    String profileId, {
    bool forceRefresh = false,
  });

  Future<ProjectItem?> createProject(ProjectDraftData draft);

  Future<void> applyToProject({
    required ProjectItem project,
    required String subject,
    required String message,
    required int attachmentsCount,
  });

  Future<List<ProjectApplicationRequest>> fetchProjectApplications(
    String projectId, {
    bool forceRefresh = false,
  });

  Future<Set<String>> fetchAppliedProjectIds({bool forceRefresh = false});
}

final class SupabaseProjectRepository implements ProjectRepository {
  SupabaseProjectRepository({required this.client});

  static const _projectsPageSize = 24;
  static const _profileProjectsPageSize = 24;
  static const _searchPageSize = 24;
  static const _applicationsPageSize = 30;

  final SupabaseClient? client;
  final _cache = TimedMemoryCache<List<ProjectItem>>(
    ttl: const Duration(minutes: 2),
  );
  final _profileCaches = <String, TimedMemoryCache<List<ProjectItem>>>{};
  final _applicationCaches =
      <String, TimedMemoryCache<List<ProjectApplicationRequest>>>{};
  final _appliedProjectsCache = TimedMemoryCache<Set<String>>(
    ttl: const Duration(minutes: 2),
  );

  @override
  Future<List<ProjectItem>> fetchProjects({bool forceRefresh = false}) async {
    return _cache.read(_fetchProjects, forceRefresh: forceRefresh);
  }

  Future<List<ProjectItem>> _fetchProjects() async {
    final remote = client;
    if (remote == null) {
      return const [];
    }

    try {
      final rows = await remote.rpc<List<dynamic>>(
        'get_projects_for_app',
        params: {'p_limit': _projectsPageSize},
      );
      return [
        for (var i = 0; i < rows.length; i++)
          projectFromSupabase(
            Map<String, dynamic>.from(rows[i] as Map),
            colorIndex: i,
          ),
      ];
    } catch (_) {
      try {
        final rows = await remote
            .from('projects')
            .select(
              'id,title,description,governorate,budget_min,budget_max,status,start_date,end_date,image_url,profile_id,profiles(full_name,avatar_url)',
            )
            .order('created_at', ascending: false)
            .limit(_projectsPageSize);
        return [
          for (var i = 0; i < rows.length; i++)
            projectFromSupabase(
              Map<String, dynamic>.from(rows[i] as Map),
              colorIndex: i,
            ),
        ];
      } catch (_) {
        return const [];
      }
    }
  }

  @override
  Future<List<ProjectItem>> searchJobs(String query) async {
    final remote = client;
    final term = _sanitizeSearchTerm(query);
    if (remote == null || term.isEmpty) {
      return const [];
    }
    try {
      final pattern = '%$term%';
      final rows = await remote
          .from('projects')
          .select(
            'id,title,description,governorate,budget_min,budget_max,status,start_date,end_date,image_url,profile_id,profiles(full_name,avatar_url)',
          )
          .or('title.ilike.$pattern,description.ilike.$pattern')
          .order('created_at', ascending: false)
          .limit(_searchPageSize);
      return [
        for (var i = 0; i < rows.length; i++)
          projectFromSupabase(
            Map<String, dynamic>.from(rows[i] as Map),
            colorIndex: i,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Strips SQL `LIKE` wildcards (`%`, `_`) and PostgREST `or()` structural
  /// characters (`,`, `(`, `)`) so raw user input can't break the filter.
  String _sanitizeSearchTerm(String query) =>
      query.replaceAll(RegExp(r'[%_,()]'), ' ').trim();

  @override
  Future<List<ProjectItem>> fetchProjectsForProfile(
    String profileId, {
    bool forceRefresh = false,
  }) {
    final cache = _profileCaches.putIfAbsent(
      profileId,
      () =>
          TimedMemoryCache<List<ProjectItem>>(ttl: const Duration(minutes: 2)),
    );
    return cache.read(
      () => _fetchProjectsForProfile(profileId),
      forceRefresh: forceRefresh,
    );
  }

  Future<List<ProjectItem>> _fetchProjectsForProfile(String profileId) async {
    final remote = client;
    if (remote == null || profileId.isEmpty) {
      return const [];
    }

    try {
      final rows = await remote.rpc<List<dynamic>>(
        'get_projects_for_app',
        params: {'p_limit': _profileProjectsPageSize},
      );
      final filtered = rows.where((row) {
        final map = Map<String, dynamic>.from(row as Map);
        return '${map['profile_id']}' == profileId;
      }).toList();
      return [
        for (var i = 0; i < filtered.length; i++)
          projectFromSupabase(
            Map<String, dynamic>.from(filtered[i] as Map),
            colorIndex: i,
          ),
      ];
    } catch (_) {
      try {
        final rows = await remote
            .from('projects')
            .select(
              'id,title,description,governorate,budget_min,budget_max,status,start_date,end_date,image_url,profile_id,profiles(full_name,avatar_url),project_details(*)',
            )
            .eq('profile_id', profileId)
            .order('created_at', ascending: false)
            .limit(_profileProjectsPageSize);
        return [
          for (var i = 0; i < rows.length; i++)
            projectFromSupabase(
              Map<String, dynamic>.from(rows[i] as Map),
              colorIndex: i,
            ),
        ];
      } catch (_) {
        return const [];
      }
    }
  }

  @override
  Future<ProjectItem?> createProject(ProjectDraftData draft) async {
    final remote = client;
    if (remote == null) {
      return null;
    }

    try {
      final createdId = await _createProjectViaRpc(remote, draft);
      if (createdId == null) {
        return null;
      }
      final createdProject = await _fetchProjectById(remote, createdId);
      _prependProject(createdProject);
      return createdProject;
    } catch (_) {
      try {
        final createdProject = await _createProjectWithTables(remote, draft);
        _prependProject(createdProject);
        return createdProject;
      } catch (error) {
        throw RepositoryFailure('تعذر نشر المشروع الآن', error);
      }
    }
  }

  @override
  Future<void> applyToProject({
    required ProjectItem project,
    required String subject,
    required String message,
    required int attachmentsCount,
  }) async {
    final remote = client;
    if (remote == null || project.id.isEmpty) {
      return;
    }

    final profileId = await _currentProfileId(remote);
    if (profileId == null) {
      throw const RepositoryFailure('سجل الدخول أولا للتقديم على المشروع');
    }
    if (project.profileId == profileId) {
      throw const RepositoryFailure('لا يمكنك التقديم على مشروعك');
    }
    final appliedIds = await _fetchAppliedProjectIds();
    if (appliedIds.contains(project.id)) {
      throw const RepositoryFailure('لقد قدمت على هذا المشروع مسبقا');
    }

    try {
      await remote.rpc(
        'apply_to_project_for_app',
        params: {
          'p_project_id': project.id,
          'p_subject': subject.trim(),
          'p_message': message.trim(),
          'p_files': [
            for (var i = 0; i < attachmentsCount; i++)
              {'name': 'attachment_${i + 1}'},
          ],
        },
      );
      _applicationCaches[project.id]?.clear();
      _appliedProjectsCache.clear();
      // Server-side `app_notify_on_project_application` trigger emits
      // the notification. No client insert here to avoid duplicates.
      return;
    } catch (_) {
      // Fall through to the table write for projects before the bridge RPC.
    }

    try {
      await remote.from('project_applications').insert({
        'project_id': project.id,
        'profile_id': profileId,
        'subject': subject.trim(),
        'message': message.trim(),
        'attachments_count': attachmentsCount,
        'status': 'pending',
      });
      _applicationCaches[project.id]?.clear();
      _appliedProjectsCache.clear();
      // Server-side `app_notify_on_project_application` trigger emits
      // the notification. No client insert here to avoid duplicates.
    } catch (error) {
      throw RepositoryFailure('تعذر إرسال طلب المشروع الآن', error);
    }
  }

  @override
  Future<Set<String>> fetchAppliedProjectIds({bool forceRefresh = false}) {
    return _appliedProjectsCache.read(
      _fetchAppliedProjectIds,
      forceRefresh: forceRefresh,
    );
  }

  Future<Set<String>> _fetchAppliedProjectIds() async {
    final remote = client;
    if (remote == null) {
      return const <String>{};
    }
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return const <String>{};
      }
      final rows = await remote
          .from('project_applications')
          .select('project_id')
          .eq('profile_id', profileId);
      return {
        for (final raw in rows)
          if ('${(raw as Map)['project_id'] ?? ''}'.isNotEmpty)
            '${raw['project_id']}',
      };
    } catch (_) {
      return const <String>{};
    }
  }

  @override
  Future<List<ProjectApplicationRequest>> fetchProjectApplications(
    String projectId, {
    bool forceRefresh = false,
  }) {
    final cache = _applicationCaches.putIfAbsent(
      projectId,
      () => TimedMemoryCache<List<ProjectApplicationRequest>>(
        ttl: const Duration(seconds: 45),
      ),
    );
    return cache.read(
      () => _fetchProjectApplications(projectId),
      forceRefresh: forceRefresh,
    );
  }

  Future<List<ProjectApplicationRequest>> _fetchProjectApplications(
    String projectId,
  ) async {
    final remote = client;
    if (remote == null || projectId.isEmpty) {
      return const [];
    }

    try {
      final rows = await remote
          .from('project_applications')
          .select(
            'id,subject,message,attachments_count,status,created_at,profiles!project_applications_profile_id_fkey(id,full_name,role,bio,avatar_url)',
          )
          .eq('project_id', projectId)
          .order('created_at', ascending: false)
          .limit(_applicationsPageSize);
      return [
        for (var i = 0; i < rows.length; i++)
          _applicationFromRow(Map<String, dynamic>.from(rows[i] as Map), i),
      ];
    } catch (_) {
      try {
        final rows = await remote
            .from('project_applications')
            .select(
              'id,subject,message,attachments_count,status,created_at,profiles(id,full_name,role,bio,avatar_url)',
            )
            .eq('project_id', projectId)
            .order('created_at', ascending: false)
            .limit(_applicationsPageSize);
        return [
          for (var i = 0; i < rows.length; i++)
            _applicationFromRow(Map<String, dynamic>.from(rows[i] as Map), i),
        ];
      } catch (_) {
        return const [];
      }
    }
  }

  ProjectApplicationRequest _applicationFromRow(
    Map<String, dynamic> row,
    int index,
  ) {
    final profile = row['profiles'] is Map
        ? Map<String, dynamic>.from(row['profiles'] as Map)
        : const <String, dynamic>{};
    final name = '${profile['full_name'] ?? ''}'.trim();
    final title = '${profile['bio'] ?? profile['role'] ?? ''}'.trim();
    return ProjectApplicationRequest(
      id: '${row['id']}',
      profileId: '${profile['id'] ?? ''}',
      name: name.isEmpty ? 'مستخدم' : name,
      title: title.isEmpty ? 'طلب تقديم' : title,
      message: '${row['message'] ?? ''}',
      status: '${row['status'] ?? 'pending'}',
      attachmentsCount: _intFrom(row['attachments_count']),
      createdAt:
          DateTime.tryParse('${row['created_at']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      color: _colorForIndex(index),
      avatarUrl: profile['avatar_url'] == null
          ? null
          : '${profile['avatar_url']}',
    );
  }

  int _intFrom(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }

  Color _colorForIndex(int index) {
    return switch (index % 4) {
      0 => AppColors.blue,
      1 => AppColors.darkBlue,
      2 => AppColors.muted,
      _ => AppColors.black,
    };
  }

  Future<String?> _createProjectViaRpc(
    SupabaseClient remote,
    ProjectDraftData draft,
  ) async {
    final response = await remote.rpc(
      'create_project_for_app',
      params: {
        'p_title': draft.title.trim(),
        'p_description': draft.description,
        'p_governorate': governorateToSupabase(draft.normalizedLocation),
        'p_tagline': draft.tagline.trim(),
        'p_category': draft.category,
        'p_project_type': draft.projectType,
        'p_work_mode': draft.workMode,
        'p_stage': draft.stage,
        'p_problem': draft.problem.trim(),
        'p_goals': draft.goals.trim(),
        'p_target_users': draft.audience.trim(),
        'p_existing_assets': draft.assetList,
        'p_required_skills': draft.requiredSkillList,
        'p_preferred_skills': draft.preferredSkillList,
        'p_tools_equipment': draft.techStackList,
        'p_seniority_level': draft.seniority,
        'p_years_experience': draft.yearsExperience,
        'p_certifications': draft.certificationList,
        'p_engineers_needed': draft.engineersNeededCount,
        'p_roles_needed': draft.roleList,
        'p_responsibilities': {'text': draft.responsibilities.trim()},
        'p_current_team_size': draft.currentTeamSize.trim(),
        'p_collaboration_tools': draft.collaborationToolList,
        'p_estimated_duration': draft.duration.trim(),
        'p_weekly_commitment': draft.weeklyCommitment,
        'p_milestones': [
          for (final item in draft.milestones.split(RegExp(r'[,،\n]')))
            if (item.trim().isNotEmpty) item.trim(),
        ],
        'p_deadline_urgency': draft.urgency,
        'p_payment_status': draft.paidStatus,
        'p_payment_model': draft.paymentModel,
        'p_currency': draft.normalizedCurrency,
        'p_bonus_incentives': draft.bonus.trim(),
        'p_budget_min': draft.budgetMin,
        'p_budget_max': draft.budgetMax,
      },
    );
    return response == null ? null : '$response';
  }

  Future<ProjectItem?> _fetchProjectById(
    SupabaseClient remote,
    String projectId,
  ) async {
    try {
      final rows = await remote.rpc<List<dynamic>>(
        'get_projects_for_app',
        params: {'p_limit': 100},
      );
      final row = rows.cast<Object?>().whereType<Map>().firstWhere(
        (row) => '${row['id']}' == projectId,
        orElse: () => const {},
      );
      if (row.isEmpty) {
        return null;
      }
      return projectFromSupabase(Map<String, dynamic>.from(row));
    } catch (_) {
      return null;
    }
  }

  Future<ProjectItem?> _createProjectWithTables(
    SupabaseClient remote,
    ProjectDraftData draft,
  ) async {
    final profileId = await _currentProfileId(remote);
    if (profileId == null) {
      return null;
    }

    final projectRow = await remote
        .from('projects')
        .insert({
          'profile_id': profileId,
          'title': draft.title.trim(),
          'description': draft.description,
          'governorate': governorateToSupabase(draft.normalizedLocation),
          'budget_min': draft.budgetMin,
          'budget_max': draft.budgetMax,
          'status': 'planning',
        })
        .select()
        .single();

    final projectId = '${projectRow['id']}';
    final details = await remote
        .from('project_details')
        .upsert({
          'project_id': projectId,
          'tagline': draft.tagline.trim(),
          'category': draft.category,
          'project_type': draft.projectType,
          'work_mode': draft.workMode,
          'stage': draft.stage,
          'problem': draft.problem.trim(),
          'goals': draft.goals.trim(),
          'target_users': draft.audience.trim(),
          'existing_assets': draft.assetList,
          'required_skills': draft.requiredSkillList,
          'preferred_skills': draft.preferredSkillList,
          'tools_equipment': draft.techStackList,
          'seniority_level': draft.seniority,
          'years_experience': draft.yearsExperience,
          'certifications': draft.certificationList,
          'engineers_needed': draft.engineersNeededCount,
          'roles_needed': draft.roleList,
          'responsibilities': {'text': draft.responsibilities.trim()},
          'current_team_size': draft.currentTeamSize.trim(),
          'collaboration_tools': draft.collaborationToolList,
          'estimated_duration': draft.duration.trim(),
          'weekly_commitment': draft.weeklyCommitment,
          'milestones': [
            for (final item in draft.milestones.split(RegExp(r'[,،\n]')))
              if (item.trim().isNotEmpty) item.trim(),
          ],
          'deadline_urgency': draft.urgency,
          'payment_status': draft.paidStatus,
          'payment_model': draft.paymentModel,
          'currency': draft.normalizedCurrency,
          'bonus_incentives': draft.bonus.trim(),
        }, onConflict: 'project_id')
        .select()
        .single();

    return projectFromSupabase({
      ...Map<String, dynamic>.from(projectRow),
      'project_details': Map<String, dynamic>.from(details),
    });
  }

  Future<String?> _currentProfileId(SupabaseClient remote) =>
      CurrentProfileResolver.instance.resolve(client: remote);

  void _prependProject(ProjectItem? project) {
    if (project == null) {
      _cache.clear();
      return;
    }
    final existing = _cache.value ?? const <ProjectItem>[];
    _cache.put([
      project,
      for (final item in existing)
        if (item.id != project.id) item,
    ]);
  }
}
