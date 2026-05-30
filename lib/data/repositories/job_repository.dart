import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/applicant_request.dart';
import '../../models/managed_listing.dart';
import '../../models/matched_work.dart';
import '../../models/my_application.dart';
import '../session/current_profile_resolver.dart';
import 'repository_failure.dart';

abstract interface class JobRepository {
  /// Jobs created by the current user, with application + accepted counts.
  Future<List<ManagedListing>> fetchMyJobs({bool forceRefresh = false});

  /// Applicants on a job the current user owns.
  Future<List<ApplicantRequest>> fetchJobApplications(String jobId);

  /// Accepts (matches) an applicant on a job. The job becomes completed and
  /// leaves the feed; the applicant is notified server-side.
  Future<void> matchJobApplicant(String applicationId);

  /// Jobs the current user applied to (for "تقديماتي").
  Future<List<MyApplication>> fetchMyJobApplications();

  /// Ids of jobs the current user already applied to (to show "تم التقديم").
  Future<Set<String>> fetchAppliedJobIds({bool forceRefresh = false});

  /// Project + job listings the given profile was matched (accepted) into.
  Future<List<MatchedWork>> fetchMatchedWorks(String profileId);
}

final class SupabaseJobRepository implements JobRepository {
  SupabaseJobRepository({required this.client});

  final SupabaseClient? client;

  Set<String>? _appliedJobIds;

  @override
  Future<List<ManagedListing>> fetchMyJobs({bool forceRefresh = false}) async {
    final remote = client;
    if (remote == null) {
      return const [];
    }
    try {
      final rows = await remote.rpc<List<dynamic>>('get_my_jobs');
      return [
        for (final row in rows)
          ManagedListing.job(Map<String, dynamic>.from(row as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<ApplicantRequest>> fetchJobApplications(String jobId) async {
    final remote = client;
    if (remote == null || jobId.isEmpty) {
      return const [];
    }
    try {
      final rows = await remote.rpc<List<dynamic>>(
        'get_job_applications',
        params: {'p_job_id': jobId},
      );
      return [
        for (var i = 0; i < rows.length; i++)
          ApplicantRequest.job(Map<String, dynamic>.from(rows[i] as Map), i),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> matchJobApplicant(String applicationId) async {
    final remote = client;
    if (remote == null || applicationId.isEmpty) {
      return;
    }
    try {
      await remote.rpc(
        'match_job_applicant',
        params: {'p_application_id': applicationId},
      );
    } on PostgrestException catch (error) {
      throw RepositoryFailure(_matchErrorMessage(error.message), error);
    } catch (error) {
      throw RepositoryFailure('تعذر إتمام المطابقة الآن', error);
    }
  }

  @override
  Future<List<MyApplication>> fetchMyJobApplications() async {
    final remote = client;
    if (remote == null) {
      return const [];
    }
    try {
      final rows = await remote.rpc<List<dynamic>>('get_my_job_applications');
      return [
        for (final row in rows)
          MyApplication.job(Map<String, dynamic>.from(row as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<Set<String>> fetchAppliedJobIds({bool forceRefresh = false}) async {
    if (!forceRefresh && _appliedJobIds != null) {
      return _appliedJobIds!;
    }
    final remote = client;
    if (remote == null) {
      return const <String>{};
    }
    try {
      final profileId = await CurrentProfileResolver.instance.resolve(
        client: remote,
      );
      if (profileId == null) {
        return const <String>{};
      }
      final rows = await remote
          .from('job_applications')
          .select('job_id')
          .eq('profile_id', profileId);
      final ids = {
        for (final raw in rows)
          if ('${(raw as Map)['job_id'] ?? ''}'.isNotEmpty) '${raw['job_id']}',
      };
      _appliedJobIds = ids;
      return ids;
    } catch (_) {
      return const <String>{};
    }
  }

  @override
  Future<List<MatchedWork>> fetchMatchedWorks(String profileId) async {
    final remote = client;
    if (remote == null || profileId.isEmpty) {
      return const [];
    }
    try {
      final rows = await remote.rpc<List<dynamic>>(
        'get_matched_works',
        params: {'p_profile_id': profileId},
      );
      return [
        for (final row in rows)
          MatchedWork.fromRow(Map<String, dynamic>.from(row as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  String _matchErrorMessage(String raw) {
    if (raw.contains('MATCH_LIMIT_REACHED')) {
      return 'تم الوصول إلى الحد الأقصى للمطابقات لهذه الوظيفة';
    }
    if (raw.contains('NOT_JOB_OWNER')) {
      return 'لا يمكنك إجراء المطابقة على وظيفة لا تملكها';
    }
    if (raw.contains('AUTH_REQUIRED')) {
      return 'سجل الدخول أولا';
    }
    return 'تعذر إتمام المطابقة الآن';
  }
}
