import 'package:flutter/material.dart';

final class PremiumCourse {
  const PremiumCourse({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.instructor,
    required this.icon,
    required this.color,
    required this.progress,
    required this.playlists,
  });

  final String id;
  final String title;
  final String subtitle;
  final String instructor;
  final IconData icon;
  final Color color;
  final double progress;
  final List<PremiumPlaylist> playlists;

  int get lessonCount {
    return playlists.fold(
      0,
      (total, playlist) => total + playlist.videos.length,
    );
  }
}

final class PremiumPlaylist {
  const PremiumPlaylist({
    required this.id,
    required this.title,
    required this.description,
    required this.videos,
  });

  final String id;
  final String title;
  final String description;
  final List<PremiumVideo> videos;

  Duration get duration {
    return videos.fold(Duration.zero, (total, video) => total + video.duration);
  }
}

final class PremiumVideo {
  const PremiumVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.videoUrl,
    this.completed = false,
  });

  final String id;
  final String title;
  final String description;
  final Duration duration;
  final String videoUrl;
  final bool completed;
}
