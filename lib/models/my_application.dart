/// One application the current user submitted — to a project or a job —
/// shown in the "تقديماتي" (my applications) screen.
final class MyApplication {
  const MyApplication({
    required this.kind,
    required this.applicationId,
    required this.refId,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.ownerName,
    required this.createdAt,
    this.ownerAvatarUrl,
  });

  /// `'project'` or `'job'`.
  final String kind;
  final String applicationId;

  /// The project / job id the application targets.
  final String refId;
  final String title;
  final String subtitle;

  /// Application status: pending / accepted / rejected / withdrawn / ...
  final String status;
  final String ownerName;
  final String? ownerAvatarUrl;
  final DateTime createdAt;

  bool get isProject => kind == 'project';
  bool get isJob => kind == 'job';
  bool get isAccepted => status == 'accepted';

  static MyApplication project(Map<String, dynamic> row) {
    final owner = '${row['owner_name'] ?? ''}'.trim();
    return MyApplication(
      kind: 'project',
      applicationId: '${row['application_id'] ?? ''}',
      refId: '${row['project_id'] ?? ''}',
      title: '${row['title'] ?? ''}'.trim(),
      subtitle: '${row['governorate'] ?? ''}'.trim(),
      status: '${row['status'] ?? 'pending'}',
      ownerName: owner.isEmpty ? 'مستخدم' : owner,
      ownerAvatarUrl: row['owner_avatar'] == null
          ? null
          : '${row['owner_avatar']}',
      createdAt:
          DateTime.tryParse('${row['created_at']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static MyApplication job(Map<String, dynamic> row) {
    final owner = '${row['owner_name'] ?? ''}'.trim();
    final company = '${row['company_name'] ?? ''}'.trim();
    final location = '${row['location'] ?? ''}'.trim();
    return MyApplication(
      kind: 'job',
      applicationId: '${row['application_id'] ?? ''}',
      refId: '${row['job_id'] ?? ''}',
      title: '${row['title'] ?? ''}'.trim(),
      subtitle: company.isNotEmpty ? company : location,
      status: '${row['status'] ?? 'pending'}',
      ownerName: owner.isEmpty ? (company.isEmpty ? 'شركة' : company) : owner,
      ownerAvatarUrl: row['owner_avatar'] == null
          ? null
          : '${row['owner_avatar']}',
      createdAt:
          DateTime.tryParse('${row['created_at']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
