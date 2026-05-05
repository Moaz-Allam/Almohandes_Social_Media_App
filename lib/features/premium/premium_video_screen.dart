import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'models/premium_course.dart';
import 'widgets/premium_video_player.dart';

class PremiumVideoScreen extends StatelessWidget {
  const PremiumVideoScreen({
    super.key,
    required this.course,
    required this.playlist,
    required this.video,
  });

  final PremiumCourse course;
  final PremiumPlaylist playlist;
  final PremiumVideo video;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        title: const Text('مشغل الدورة'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PremiumVideoPlayer(video: video),
          const SizedBox(height: 18),
          Text(
            video.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            video.description,
            style: TextStyle(color: context.appMuted, height: 1.45),
          ),
          const SizedBox(height: 18),
          _InfoRow(icon: course.icon, label: course.title),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.playlist_play, label: playlist.title),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
