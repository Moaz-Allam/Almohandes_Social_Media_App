import '../../core/constants/app_colors.dart';
import '../../models/feed_post_model.dart';

FeedPostModel feedPostFromSupabase(
  Map<String, dynamic> row, {
  int colorIndex = 0,
}) {
  final profile = _firstMap(row['profiles']);
  final likes = row['likes_count'] ?? row['reactions_count'] ?? 0;
  final comments = row['comments_count'] ?? 0;
  final name = profile?['full_name'] ?? row['full_name'] ?? 'مستخدم المهندس';
  final role = profile?['role'] ?? row['role'] ?? 'مهندس';

  return FeedPostModel(
    id: '${row['post_id'] ?? row['id'] ?? ''}',
    profileId: row['profile_id'] == null ? null : '${row['profile_id']}',
    name: '$name',
    headline: _headlineForRole('$role'),
    time: 'حديثا',
    body: '${row['content'] ?? ''}',
    reactions: '$likes',
    comments: '$comments تعليق',
    avatarColor: switch (colorIndex % 3) {
      0 => AppColors.darkBlue,
      1 => AppColors.blue,
      _ => AppColors.muted,
    },
    showMedia: row['image_url'] != null,
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
    'engineer' => 'مهندس · منصة المهندس',
    'contractor' => 'شركة مقاولات',
    'craftsman' => 'حرفي',
    'worker' => 'عامل بناء',
    'machinery' => 'مزود آليات',
    _ => role,
  };
}
