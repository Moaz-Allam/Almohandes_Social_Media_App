import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart' show Color;

import '../../core/constants/app_colors.dart';
import '../../models/account_type.dart';
import '../../models/network_person.dart';
import '../../models/profile_form.dart';
import '../cache/timed_memory_cache.dart';
import '../mappers/supabase_enum_mapper.dart';

abstract interface class ProfileRepository {
  Future<ProfileForm?> currentProfile({bool forceRefresh = false});

  Future<List<NetworkPerson>> fetchNetworkProfiles({
    required AccountType viewerType,
    required bool companies,
    bool forceRefresh = false,
  });

  Future<List<NetworkPerson>> fetchIncomingConnectionRequests({
    bool forceRefresh = false,
  });

  Future<void> requestConnection(String receiverProfileId);

  Future<void> followProfile(String followingProfileId);

  Future<void> answerConnectionRequest({
    required String requestId,
    required bool accept,
  });
}

final class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository({required this.client});

  final SupabaseClient? client;
  final _cache = TimedMemoryCache<ProfileForm?>(
    ttl: const Duration(minutes: 5),
  );
  final _networkCaches = <String, TimedMemoryCache<List<NetworkPerson>>>{};
  final _incomingRequestsCache = TimedMemoryCache<List<NetworkPerson>>(
    ttl: const Duration(seconds: 45),
  );

  @override
  Future<ProfileForm?> currentProfile({bool forceRefresh = false}) async {
    return _cache.read(_fetchCurrentProfile, forceRefresh: forceRefresh);
  }

  Future<ProfileForm?> _fetchCurrentProfile() async {
    final remote = client;
    final userId = remote?.auth.currentUser?.id;
    if (remote == null || userId == null) {
      return null;
    }

    try {
      final row = await remote
          .from('profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return row == null ? null : _profileFormFromRow(row);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<NetworkPerson>> fetchNetworkProfiles({
    required AccountType viewerType,
    required bool companies,
    bool forceRefresh = false,
  }) async {
    final key = '${viewerType.name}:${companies ? 'companies' : 'people'}';
    final cache = _networkCaches.putIfAbsent(
      key,
      () => TimedMemoryCache<List<NetworkPerson>>(
        ttl: const Duration(minutes: 2),
      ),
    );
    return cache.read(
      () => _fetchNetworkProfiles(viewerType: viewerType, companies: companies),
      forceRefresh: forceRefresh,
    );
  }

  Future<List<NetworkPerson>> _fetchNetworkProfiles({
    required AccountType viewerType,
    required bool companies,
  }) async {
    final remote = client;
    if (remote == null || !_canViewNetwork(viewerType)) {
      return const [];
    }

    try {
      final rows = await remote.rpc<List<dynamic>>(
        'get_network_profiles_for_app',
        params: {
          'p_audience': companies ? 'companies' : 'people',
          'p_limit': 60,
        },
      );
      return [
        for (var i = 0; i < rows.length; i++)
          _networkPersonFromRow(
            Map<String, dynamic>.from(rows[i] as Map),
            colorIndex: i,
          ),
      ];
    } catch (_) {
      try {
        var query = remote
            .from('profiles')
            .select(
              'id,full_name,username,role,governorate,bio,experience_years,projects_count,followers_count,avatar_url,is_verified',
            );

        if (companies) {
          if (viewerType != AccountType.engineer) {
            return const [];
          }
          query = query.inFilter('role', const ['contractor', 'client']);
        } else {
          query = switch (viewerType) {
            AccountType.engineer => query.inFilter('role', const [
              'engineer',
              'craftsman',
              'worker',
              'machinery',
            ]),
            AccountType.company => query.eq('role', 'engineer'),
            AccountType.craftsman ||
            AccountType.worker ||
            AccountType.equipment => query.eq('role', '__none__'),
          };
        }

        final rows = await query
            .order('is_verified', ascending: false)
            .order('projects_count', ascending: false)
            .limit(60);
        return [
          for (var i = 0; i < rows.length; i++)
            _networkPersonFromRow(
              Map<String, dynamic>.from(rows[i] as Map),
              colorIndex: i,
            ),
        ];
      } catch (_) {
        return const [];
      }
    }
  }

  ProfileForm _profileFormFromRow(Map<String, dynamic> row) {
    final fullName = '${row['full_name'] ?? ''}'.trim();
    final parts = fullName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final firstName = parts.isEmpty ? '' : parts.first;
    final lastName = parts.length <= 1 ? '' : parts.skip(1).join(' ');
    final type = accountTypeFromSupabaseRole('${row['role'] ?? ''}');
    final location = governorateFromSupabase('${row['governorate'] ?? ''}');
    final bio = '${row['bio'] ?? ''}'.trim();

    return ProfileForm(
      id: row['id'] == null ? null : '${row['id']}',
      avatarUrl: row['avatar_url'] == null ? null : '${row['avatar_url']}',
      followersCount: _intFrom(row['followers_count']),
      followingCount: _intFrom(row['following_count']),
      postsCount: _intFrom(row['posts_count']),
      projectsCount: _intFrom(row['projects_count']),
      isPremium:
          '${row['subscription_status'] ?? ''}' == 'active' ||
          row['has_pro_badge'] == true,
      email: '${row['email'] ?? ''}',
      firstName: firstName,
      lastName: lastName,
      headline: '${type.label} · $location',
      location: location,
      industry: type.label,
      company: type == AccountType.company ? fullName : '',
      role: type.label,
      about: bio.isEmpty ? type.description : bio,
      skills: const {},
      languages: const {},
      openToWork: type != AccountType.company,
      profilePublic: true,
      jobAlerts: false,
    );
  }

  int _intFrom(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }

  @override
  Future<List<NetworkPerson>> fetchIncomingConnectionRequests({
    bool forceRefresh = false,
  }) {
    return _incomingRequestsCache.read(
      _fetchIncomingConnectionRequests,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<NetworkPerson>> _fetchIncomingConnectionRequests() async {
    final remote = client;
    if (remote == null) {
      return const [];
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return const [];
      }
      final rows = await remote
          .from('connection_requests')
          .select(
            'id,created_at,requester_profile_id,profiles!connection_requests_requester_profile_id_fkey(id,full_name,username,role,governorate,bio,experience_years,projects_count,followers_count,avatar_url,is_verified)',
          )
          .eq('receiver_profile_id', profileId)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(50);
      return [
        for (var i = 0; i < rows.length; i++)
          _requestPersonFromRow(
            Map<String, dynamic>.from(rows[i] as Map),
            colorIndex: i,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> requestConnection(String receiverProfileId) async {
    final remote = client;
    if (remote == null || receiverProfileId.isEmpty) {
      return;
    }

    try {
      await remote.rpc(
        'request_connection_for_app',
        params: {'p_receiver_profile_id': receiverProfileId},
      );
    } catch (_) {
      try {
        final profileId = await _currentProfileId(remote);
        if (profileId == null) {
          return;
        }
        await remote.from('connection_requests').upsert({
          'requester_profile_id': profileId,
          'receiver_profile_id': receiverProfileId,
          'status': 'pending',
        }, onConflict: 'requester_profile_id,receiver_profile_id');
      } catch (_) {
        // Connection request remains optimistic in the UI.
      }
    }
  }

  @override
  Future<void> followProfile(String followingProfileId) async {
    final remote = client;
    if (remote == null || followingProfileId.isEmpty) {
      return;
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null || profileId == followingProfileId) {
        return;
      }
      await remote.from('followers').upsert({
        'follower_id': profileId,
        'following_id': followingProfileId,
      }, onConflict: 'follower_id,following_id');
      _networkCaches.clear();
    } catch (_) {
      // Follow stays best-effort when the optional relation is unavailable.
    }
  }

  @override
  Future<void> answerConnectionRequest({
    required String requestId,
    required bool accept,
  }) async {
    final remote = client;
    if (remote == null || requestId.isEmpty) {
      return;
    }

    try {
      await remote
          .from('connection_requests')
          .update({
            'status': accept ? 'accepted' : 'rejected',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);
      _incomingRequestsCache.clear();
    } catch (_) {
      // Keep the local visual decision even if the optional table is missing.
    }
  }

  NetworkPerson _requestPersonFromRow(
    Map<String, dynamic> row, {
    required int colorIndex,
  }) {
    final profile = row['profiles'] is Map
        ? Map<String, dynamic>.from(row['profiles'] as Map)
        : <String, dynamic>{};
    final person = _networkPersonFromRow(profile, colorIndex: colorIndex);
    return NetworkPerson(
      id: '${row['id']}',
      profileId: person.id,
      name: person.name,
      title: person.title,
      color: person.color,
      badge: person.badge,
      contextLine: person.contextLine,
      actionLabel: person.actionLabel,
      isCompany: person.isCompany,
    );
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

  bool _canViewNetwork(AccountType viewerType) {
    return viewerType == AccountType.engineer ||
        viewerType == AccountType.company;
  }

  NetworkPerson _networkPersonFromRow(
    Map<String, dynamic> row, {
    required int colorIndex,
  }) {
    final role = '${row['role'] ?? ''}';
    final type = accountTypeFromSupabaseRole(role);
    final fullName = '${row['full_name'] ?? row['username'] ?? ''}'.trim();
    final name = fullName.isEmpty ? 'مستخدم' : fullName;
    final location = governorateFromSupabase('${row['governorate'] ?? ''}');
    final experienceYears = row['experience_years'];
    final projectsCount = row['projects_count'];
    final bio = '${row['bio'] ?? ''}'.trim();

    return NetworkPerson(
      id: '${row['id']}',
      name: name,
      title: _networkTitle(type, bio),
      color: _networkColor(colorIndex),
      badge: row['is_verified'] == true ? 'موثق' : null,
      contextLine: _networkContextLine(
        location: location,
        experienceYears: experienceYears,
        projectsCount: projectsCount,
      ),
      actionLabel: type == AccountType.company ? 'متابعة' : 'تواصل',
      isCompany: type == AccountType.company,
    );
  }

  String _networkTitle(AccountType type, String bio) {
    if (bio.isNotEmpty) {
      return bio;
    }
    return switch (type) {
      AccountType.engineer => 'مهندس',
      AccountType.company => 'شركة مشاريع',
      AccountType.craftsman => 'حرفي',
      AccountType.worker => 'عامل',
      AccountType.equipment => 'آليات ومعدات',
    };
  }

  String _networkContextLine({
    required String location,
    required Object? experienceYears,
    required Object? projectsCount,
  }) {
    final years = int.tryParse('$experienceYears');
    if (years != null && years > 0) {
      return '$location · خبرة $years سنوات';
    }
    final projects = int.tryParse('$projectsCount');
    if (projects != null && projects > 0) {
      return '$location · $projects مشاريع';
    }
    return '$location · العراق';
  }

  Color _networkColor(int index) {
    return switch (index % 4) {
      0 => AppColors.blue,
      1 => AppColors.darkBlue,
      2 => AppColors.muted,
      _ => AppColors.black,
    };
  }
}
