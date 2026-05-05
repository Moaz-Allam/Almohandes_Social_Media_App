import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'models/premium_course.dart';
import 'premium_video_screen.dart';
import 'widgets/playlist_video_tile.dart';

class PremiumCourseScreen extends StatelessWidget {
  const PremiumCourseScreen({super.key, required this.course});

  final PremiumCourse course;

  void _openVideo(
    BuildContext context,
    PremiumPlaylist playlist,
    PremiumVideo video,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PremiumVideoScreen(
          course: course,
          playlist: playlist,
          video: video,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (course.progress * 100).round();

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text('تفاصيل الدورة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: course.color.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.appBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(course.icon, color: course.color, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  course.subtitle,
                  style: TextStyle(color: context.appMuted, height: 1.45),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: course.progress,
                    minHeight: 7,
                    backgroundColor: context.appSurface,
                    valueColor: AlwaysStoppedAnimation<Color>(course.color),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$percentage% من الدورة مكتمل',
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'قوائم التشغيل',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final playlist in course.playlists) ...[
            _PlaylistPanel(
              playlist: playlist,
              onVideoTap: (video) => _openVideo(context, playlist, video),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PlaylistPanel extends StatelessWidget {
  const _PlaylistPanel({required this.playlist, required this.onVideoTap});

  final PremiumPlaylist playlist;
  final ValueChanged<PremiumVideo> onVideoTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            playlist.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            playlist.description,
            style: TextStyle(color: context.appMuted, height: 1.35),
          ),
          const SizedBox(height: 8),
          for (final entry in playlist.videos.indexed)
            PlaylistVideoTile(
              video: entry.$2,
              index: entry.$1,
              onTap: () => onVideoTap(entry.$2),
            ),
        ],
      ),
    );
  }
}
