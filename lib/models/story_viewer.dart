/// A single person who viewed a story, shown to the story's creator in the
/// "who saw my story" list.
final class StoryViewer {
  const StoryViewer({
    required this.profileId,
    required this.name,
    this.role = '',
    this.avatarUrl,
    this.viewedAt,
  });

  final String profileId;
  final String name;
  final String role;
  final String? avatarUrl;
  final DateTime? viewedAt;
}
