/// A project or job created by the current user, shown in the owner's
/// "created items" management list with applicant counts.
final class ManagedListing {
  const ManagedListing({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.applicationsCount,
    required this.acceptedCount,
    this.engineersNeeded,
    this.isActive = true,
  });

  /// `'project'` or `'job'`.
  final String kind;
  final String id;
  final String title;
  final String subtitle;
  final String status;
  final int applicationsCount;
  final int acceptedCount;

  /// How many people a project needs. Null for jobs (always single match).
  final int? engineersNeeded;
  final bool isActive;

  bool get isProject => kind == 'project';
  bool get isJob => kind == 'job';

  /// True once the listing is fully matched and removed from the feed.
  bool get isCompleted => status == 'completed';

  /// Remaining match slots (1 for an open job, engineersNeeded-accepted for a
  /// project).
  int get remainingSlots {
    if (isJob) {
      return acceptedCount >= 1 ? 0 : 1;
    }
    final needed = engineersNeeded ?? 1;
    final left = needed - acceptedCount;
    return left < 0 ? 0 : left;
  }

  static ManagedListing project(Map<String, dynamic> row) {
    return ManagedListing(
      kind: 'project',
      id: '${row['id'] ?? ''}',
      title: '${row['title'] ?? ''}'.trim(),
      subtitle: '${row['governorate'] ?? row['description'] ?? ''}'.trim(),
      status: '${row['status'] ?? 'planning'}',
      applicationsCount: _int(row['applications_count']),
      acceptedCount: _int(row['accepted_count']),
      engineersNeeded: _int(row['engineers_needed'], fallback: 1),
    );
  }

  static ManagedListing job(Map<String, dynamic> row) {
    final company = '${row['company_name'] ?? ''}'.trim();
    final location = '${row['location'] ?? ''}'.trim();
    final subtitle = company.isNotEmpty ? company : location;
    return ManagedListing(
      kind: 'job',
      id: '${row['id'] ?? ''}',
      title: '${row['title'] ?? ''}'.trim(),
      subtitle: subtitle,
      status: '${row['status'] ?? 'open'}',
      applicationsCount: _int(row['applications_count']),
      acceptedCount: _int(row['accepted_count']),
      isActive: row['is_active'] == null ? true : row['is_active'] == true,
    );
  }

  static int _int(Object? value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? fallback;
  }
}
