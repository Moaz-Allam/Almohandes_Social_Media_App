enum SavedContentType { post, reel, project, company }

final class SavedContent {
  const SavedContent({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.detail,
  });

  final String id;
  final SavedContentType type;
  final String title;
  final String subtitle;
  final String detail;
}
