import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../models/premium_course.dart';

class PlaylistVideoTile extends StatelessWidget {
  const PlaylistVideoTile({
    super.key,
    required this.video,
    required this.index,
    required this.onTap,
  });

  final PremiumVideo video;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: video.completed ? context.appPaleBlue : context.appSurfaceAlt,
          shape: BoxShape.circle,
        ),
        child: Icon(
          video.completed ? Icons.check : Icons.play_arrow,
          color: video.completed ? AppColors.blue : context.appMuted,
        ),
      ),
      title: Text(
        video.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        _formatDuration(video.duration),
        style: TextStyle(color: context.appMuted),
      ),
      trailing: Text(
        '${index + 1}',
        style: TextStyle(color: context.appMuted, fontWeight: FontWeight.w800),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
