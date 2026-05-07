import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../features/premium/models/premium_course.dart';
import '../cache/timed_memory_cache.dart';

abstract interface class CourseRepository {
  Future<List<PremiumCourse>> fetchPremiumCourses({bool forceRefresh = false});
}

final class SupabaseCourseRepository implements CourseRepository {
  SupabaseCourseRepository({required this.client});

  final SupabaseClient? client;
  final _cache = TimedMemoryCache<List<PremiumCourse>>(
    ttl: const Duration(minutes: 3),
  );

  @override
  Future<List<PremiumCourse>> fetchPremiumCourses({bool forceRefresh = false}) {
    return _cache.read(_fetchPremiumCourses, forceRefresh: forceRefresh);
  }

  Future<List<PremiumCourse>> _fetchPremiumCourses() async {
    final remote = client;
    if (remote == null) {
      return const [];
    }

    final courses = await _fetchAppCourses(remote);
    if (courses.isNotEmpty) {
      return courses;
    }
    return _fetchAdminCourses(remote);
  }

  Future<List<PremiumCourse>> _fetchAppCourses(SupabaseClient remote) async {
    try {
      final profileId = await _currentProfileId(remote);
      final progressByCourse = await _progressByCourse(remote, profileId);
      final rows = await remote
          .from('courses')
          .select(
            'id,title_ar,title_en,description_ar,description_en,category,video_url,duration_minutes,sort_order',
          )
          .eq('is_active', true)
          .order('sort_order')
          .order('created_at', ascending: false);

      return [
        for (var i = 0; i < rows.length; i++)
          _courseFromAppRow(
            Map<String, dynamic>.from(rows[i] as Map),
            index: i,
            progress: progressByCourse['${rows[i]['id']}'],
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<List<PremiumCourse>> _fetchAdminCourses(SupabaseClient remote) async {
    try {
      final rows = await remote
          .from('admin_courses')
          .select(
            'id,name,name_ar,description,description_ar,sort_order,admin_lectures(id,title,title_ar,description,description_ar,duration_minutes,sort_order,status,admin_lecture_assets(id,type,storage_path,file_name,is_primary,sort_order))',
          )
          .eq('is_active', true)
          .order('sort_order');
      return [
        for (var i = 0; i < rows.length; i++)
          _courseFromAdminRow(Map<String, dynamic>.from(rows[i] as Map), i),
      ].where((course) => course.lessonCount > 0).toList();
    } catch (_) {
      return const [];
    }
  }

  PremiumCourse _courseFromAppRow(
    Map<String, dynamic> row, {
    required int index,
    required _CourseProgress? progress,
  }) {
    final id = '${row['id']}';
    final title = _text(row['title_ar'], row['title_en'], fallback: 'دورة');
    final description = _text(
      row['description_ar'],
      row['description_en'],
      fallback: 'لا يوجد وصف لهذه الدورة بعد.',
    );
    final durationMinutes = _intFrom(row['duration_minutes']);
    final video = PremiumVideo(
      id: id,
      title: title,
      description: description,
      duration: Duration(minutes: durationMinutes),
      videoUrl: '${row['video_url'] ?? ''}',
      completed: progress?.isCompleted ?? false,
    );

    return PremiumCourse(
      id: id,
      title: title,
      subtitle: description,
      instructor: 'منصة المهندس',
      icon: _iconFor('${row['category'] ?? ''}'),
      color: _colorFor(index),
      progress: (progress?.percentage ?? 0) / 100,
      playlists: [
        PremiumPlaylist(
          id: '$id-lessons',
          title: 'الدروس',
          description: 'قائمة فيديوهات الدورة المتاحة لحسابك.',
          videos: [video],
        ),
      ],
    );
  }

  PremiumCourse _courseFromAdminRow(Map<String, dynamic> row, int index) {
    final id = '${row['id']}';
    final lectures = _maps(row['admin_lectures'])
      ..sort(
        (a, b) =>
            _intFrom(a['sort_order']).compareTo(_intFrom(b['sort_order'])),
      );
    final videos = <PremiumVideo>[
      for (final lecture in lectures)
        if ('${lecture['status'] ?? 'published'}' == 'published')
          _videoFromLecture(lecture),
    ].where((video) => video.videoUrl.trim().isNotEmpty).toList();

    return PremiumCourse(
      id: id,
      title: _text(row['name_ar'], row['name'], fallback: 'دورة'),
      subtitle: _text(
        row['description_ar'],
        row['description'],
        fallback: 'لا يوجد وصف لهذه الدورة بعد.',
      ),
      instructor: 'منصة المهندس',
      icon: Icons.school_outlined,
      color: _colorFor(index),
      progress: videos.isEmpty
          ? 0
          : videos.where((video) => video.completed).length / videos.length,
      playlists: [
        PremiumPlaylist(
          id: '$id-playlist',
          title: 'الدروس',
          description: 'محاضرات الدورة المنشورة من لوحة الإدارة.',
          videos: videos,
        ),
      ],
    );
  }

  PremiumVideo _videoFromLecture(Map<String, dynamic> lecture) {
    final assets = _maps(lecture['admin_lecture_assets'])
      ..sort((a, b) {
        final primaryCompare = (b['is_primary'] == true ? 1 : 0).compareTo(
          a['is_primary'] == true ? 1 : 0,
        );
        if (primaryCompare != 0) {
          return primaryCompare;
        }
        return _intFrom(a['sort_order']).compareTo(_intFrom(b['sort_order']));
      });
    final videoAsset = _firstOrNull(
      assets.where((asset) => '${asset['type']}' == 'video'),
    );
    final asset = videoAsset ?? _firstOrNull(assets);
    return PremiumVideo(
      id: '${lecture['id']}',
      title: _text(lecture['title_ar'], lecture['title'], fallback: 'درس'),
      description: _text(
        lecture['description_ar'],
        lecture['description'],
        fallback: 'لا يوجد وصف لهذا الدرس بعد.',
      ),
      duration: Duration(minutes: _intFrom(lecture['duration_minutes'])),
      videoUrl: '${asset?['storage_path'] ?? ''}',
    );
  }

  Future<Map<String, _CourseProgress>> _progressByCourse(
    SupabaseClient remote,
    String? profileId,
  ) async {
    if (profileId == null) {
      return const {};
    }
    try {
      final rows = await remote
          .from('course_progress')
          .select('course_id,progress_percentage,is_completed')
          .eq('profile_id', profileId);
      return {
        for (final row in rows)
          '${row['course_id']}': _CourseProgress(
            percentage: _intFrom(row['progress_percentage']).clamp(0, 100),
            isCompleted: row['is_completed'] == true,
          ),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<String?> _currentProfileId(SupabaseClient remote) async {
    final userId = remote.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    final row = await remote
        .from('profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : '${row['id']}';
  }

  String _text(Object? ar, Object? en, {required String fallback}) {
    final arabic = '${ar ?? ''}'.trim();
    if (arabic.isNotEmpty) {
      return arabic;
    }
    final english = '${en ?? ''}'.trim();
    return english.isEmpty ? fallback : english;
  }

  List<Map<String, dynamic>> _maps(Object? value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }
    return [
      for (final item in value)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }

  int _intFrom(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }

  Color _colorFor(int index) {
    return switch (index % 4) {
      0 => AppColors.blue,
      1 => AppColors.darkBlue,
      2 => AppColors.muted,
      _ => AppColors.black,
    };
  }

  T? _firstOrNull<T>(Iterable<T> values) {
    for (final value in values) {
      return value;
    }
    return null;
  }

  IconData _iconFor(String category) {
    return switch (category) {
      'practical' => Icons.engineering_outlined,
      'training' => Icons.workspace_premium_outlined,
      'theoretical' => Icons.menu_book_outlined,
      _ => Icons.school_outlined,
    };
  }
}

final class _CourseProgress {
  const _CourseProgress({required this.percentage, required this.isCompleted});

  final int percentage;
  final bool isCompleted;
}
