import '../../core/constants/app_colors.dart';
import '../../models/feed_post_model.dart';

FeedPostModel feedPostFromSupabase(
  Map<String, dynamic> row, {
  int colorIndex = 0,
}) {
  final profile = _firstMap(row['profiles']);
  final likes = row['likes_count'] ?? row['reactions_count'] ?? 0;
  final comments = row['comments_count'] ?? 0;
  final name = profile?['full_name'] ?? row['full_name'] ?? 'مستخدم';
  final role = profile?['role'] ?? row['role'] ?? 'مهندس';
  final imageUrl = '${row['image_url'] ?? row['media_url'] ?? ''}';
  final postType = '${row['post_type'] ?? row['media_type'] ?? ''}';
  final mediaType = postType == 'reel' || postType == 'video'
      ? 'reel'
      : imageUrl.isNotEmpty
      ? 'image'
      : 'text';

  return FeedPostModel(
    id: '${row['post_id'] ?? row['id'] ?? ''}',
    profileId: row['profile_id'] == null ? null : '${row['profile_id']}',
    name: '$name',
    headline: _headlineForRole('$role'),
    time: _exactDateTime(row['created_at']),
    body: '${row['content'] ?? ''}',
    reactions: '$likes',
    comments: '$comments تعليق',
    avatarColor: switch (colorIndex % 3) {
      0 => AppColors.darkBlue,
      1 => AppColors.blue,
      _ => AppColors.muted,
    },
    showMedia: imageUrl.isNotEmpty,
    mediaUrl: imageUrl,
    mediaType: mediaType,
    avatarUrl: profile?['avatar_url'] == null
        ? null
        : '${profile?['avatar_url']}',
  );
}

Map<String, dynamic>? _firstMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is List &&
      value.isNotEmpty &&
      value.first is Map<String, dynamic>) {
    return value.first as Map<String, dynamic>;
  }
  return null;
}

String _headlineForRole(String role) {
  return switch (role) {
    'engineer' => 'مهندس',
    'contractor' => 'شركة مقاولات',
    'craftsman' => 'حرفي',
    'worker' => 'عامل بناء',
    'machinery' => 'مزود آليات',
    _ => role.isEmpty ? 'مستخدم' : role,
  };
}

String _exactDateTime(Object? value) {
  final date = DateTime.tryParse('$value')?.toLocal();
  if (date == null) {
    return '';
  }
  String two(int number) => number.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
}
