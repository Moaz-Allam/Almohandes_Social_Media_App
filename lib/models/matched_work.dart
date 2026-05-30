/// A project or job the profile was matched (accepted) into — shown in the
/// profile's "الأعمال" tab.
final class MatchedWork {
  const MatchedWork({
    required this.kind,
    required this.refId,
    required this.title,
    required this.subtitle,
    required this.ownerName,
    this.ownerAvatarUrl,
    this.matchedAt,
  });

  /// `'project'` or `'job'`.
  final String kind;
  final String refId;
  final String title;
  final String subtitle;
  final String ownerName;
  final String? ownerAvatarUrl;
  final DateTime? matchedAt;

  bool get isProject => kind == 'project';
  bool get isJob => kind == 'job';

  static MatchedWork fromRow(Map<String, dynamic> row) {
    final owner = '${row['owner_name'] ?? ''}'.trim();
    return MatchedWork(
      kind: '${row['kind'] ?? 'project'}',
      refId: '${row['ref_id'] ?? ''}',
      title: '${row['title'] ?? ''}'.trim(),
      subtitle: '${row['subtitle'] ?? ''}'.trim(),
      ownerName: owner.isEmpty ? 'مستخدم' : owner,
      ownerAvatarUrl: row['owner_avatar'] == null
          ? null
          : '${row['owner_avatar']}',
      matchedAt: DateTime.tryParse('${row['matched_at']}'),
    );
  }
}
