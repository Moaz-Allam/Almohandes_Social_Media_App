import 'package:supabase_flutter/supabase_flutter.dart';

import '../session/current_profile_resolver.dart';
import 'package:flutter/material.dart' show Color;

import '../../core/constants/app_colors.dart';
import '../../models/account_type.dart';
import '../../models/network_person.dart';
import '../../models/profile_form.dart';
import '../cache/timed_memory_cache.dart';
import '../mappers/supabase_enum_mapper.dart';
import 'repository_failure.dart';

abstract interface class ProfileRepository {
  Future<ProfileForm?> currentProfile({bool forceRefresh = false});

  /// Persists the editable profile fields. Every parameter is optional; only
  /// the non-null ones are written. [governorate] must already be the storage
  /// slug (use [governorateToSupabase]); [skills] replaces the stored set.
  Future<void> updateCurrentProfile({
    String? about,
    String? avatarUrl,
    String? coverUrl,
    String? fullName,
    String? governorate,
    List<String>? skills,
  });

  /// Flip the current user's profile between public and private.
  Future<void> setProfilePrivacy(bool isPrivate);

  /// Whether the given profile is private (its posts are connection-only).
  Future<bool> isProfilePrivate(String profileId);

  Future<void> deleteCurrentProfile();

  Future<List<NetworkPerson>> fetchNetworkProfiles({
    required AccountType viewerType,
    required bool companies,
    bool forceRefresh = false,
  });

  /// Server-side search across all profiles by name / username / bio. Returns
  /// up to a page of matches (excluding the current user); empty when [query]
  /// is blank.
  Future<List<NetworkPerson>> searchPeople(String query);

  Future<List<NetworkPerson>> fetchIncomingConnectionRequests({
    bool forceRefresh = false,
  });

  /// Profiles that follow the current user.
  Future<List<NetworkPerson>> fetchMyFollowers({bool forceRefresh = false});

  /// Profiles the current user follows.
  Future<List<NetworkPerson>> fetchMyFollowing({bool forceRefresh = false});

  /// Profiles with whom the current user has an accepted connection.
  Future<List<NetworkPerson>> fetchMyConnections({bool forceRefresh = false});

  Future<void> requestConnection(String receiverProfileId);

  Future<String> connectionStatus(String otherProfileId);

  Future<void> followProfile(String followingProfileId);

  Future<void> unfollowProfile(String followingProfileId);

  Future<bool> isFollowingProfile(String followingProfileId);

  Future<void> answerConnectionRequest({
    required String requestId,
    required bool accept,
  });

  /// Returns simple counts (followers / following / connections) for the
  /// given profile, or all zeros if the data isn't available.
  Future<ProfileStats> fetchProfileStats(String profileId);
}

class ProfileStats {
  const ProfileStats({
    required this.followers,
    required this.following,
    required this.connections,
  });

  static const empty = ProfileStats(
    followers: 0,
    following: 0,
    connections: 0,
  );

  final int followers;
  final int following;
  final int connections;
}

final class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository({required this.client});

  static const _networkPageSize = 30;
  static const _searchPageSize = 30;
  static const _incomingRequestsPageSize = 30;

  final SupabaseClient? client;
  final _cache = TimedMemoryCache<ProfileForm?>(
    ttl: const Duration(minutes: 5),
  );
  final _networkCaches = <String, TimedMemoryCache<List<NetworkPerson>>>{};
  final _incomingRequestsCache = TimedMemoryCache<List<NetworkPerson>>(
    ttl: const Duration(seconds: 45),
  );
  final _followersCache = TimedMemoryCache<List<NetworkPerson>>(
    ttl: const Duration(minutes: 1),
  );
  final _followingCache = TimedMemoryCache<List<NetworkPerson>>(
    ttl: const Duration(minutes: 1),
  );
  final _connectionsCache = TimedMemoryCache<List<NetworkPerson>>(
    ttl: const Duration(minutes: 1),
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

    // Owner read goes through the SECURITY DEFINER `get_my_profile` RPC so it
    // can include the email/phone columns that are no longer granted to
    // `authenticated` for direct table reads (see the profile_contact_privacy
    // migration). Falls back to a direct select on older backends that don't
    // have the RPC yet.
    try {
      final row = _firstRowOrNull(await remote.rpc('get_my_profile'));
      if (row != null) {
        return _profileFormFromRow(row);
      }
    } catch (_) {
      // RPC missing/failed — fall through to the legacy direct read.
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

  /// Normalizes a Supabase RPC result (which may be a `List` of rows or a
  /// single `Map`) into the first row as a `Map<String, dynamic>`, or null.
  Map<String, dynamic>? _firstRowOrNull(dynamic result) {
    if (result is List) {
      if (result.isEmpty) {
        return null;
      }
      final first = result.first;
      return first is Map ? Map<String, dynamic>.from(first) : null;
    }
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return null;
  }

  @override
  Future<void> updateCurrentProfile({
    String? about,
    String? avatarUrl,
    String? coverUrl,
    String? fullName,
    String? governorate,
    List<String>? skills,
  }) async {
    final remote = client;
    final userId = remote?.auth.currentUser?.id;
    if (remote == null || userId == null) {
      return;
    }

    final values = <String, dynamic>{};
    if (about != null) {
      values['bio'] = about;
    }
    if (avatarUrl != null) {
      values['avatar_url'] = avatarUrl;
    }
    if (coverUrl != null) {
      // Write both columns. There's a server-side trigger that syncs them,
      // but it doesn't always fire across PostgREST partial updates, so
      // we set them explicitly to avoid the profile UI flickering between
      // the new cover and a stale one read from the other column.
      values['cover_url'] = coverUrl;
      values['cover_photo_url'] = coverUrl;
    }
    if (fullName != null) {
      values['full_name'] = fullName;
    }
    if (governorate != null) {
      values['governorate'] = governorate;
    }
    if (skills != null) {
      values['skills'] = skills;
    }
    if (values.isEmpty) {
      return;
    }
    values['updated_at'] = DateTime.now().toIso8601String();

    try {
      await remote.from('profiles').update(values).eq('user_id', userId);
      _cache.clear();
      return;
    } catch (_) {
      // Some deployments lack optional columns (cover_url, skills) or have a
      // server trigger that conflicts with a partial update. Retry once with
      // the most fragile columns dropped so the core edits still persist.
      final fallbackValues = Map<String, dynamic>.from(values)
        ..remove('cover_url')
        ..remove('skills');
      // Only updated_at left → nothing meaningful to retry.
      if (fallbackValues.length <= 1) {
        return;
      }
      try {
        await remote
            .from('profiles')
            .update(fallbackValues)
            .eq('user_id', userId);
        _cache.clear();
      } catch (_) {
        // Local optimistic profile state remains authoritative for the session.
      }
    }
  }

  @override
  Future<void> setProfilePrivacy(bool isPrivate) async {
    final remote = client;
    final userId = remote?.auth.currentUser?.id;
    if (remote == null || userId == null) {
      return;
    }
    try {
      await remote
          .from('profiles')
          .update({
            'is_private': isPrivate,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);
      _cache.clear();
    } catch (_) {
      // Privacy column may be missing on older deployments; the local
      // session flag still drives the UI toggle.
    }
  }

  @override
  Future<bool> isProfilePrivate(String profileId) async {
    final remote = client;
    if (remote == null || profileId.isEmpty) {
      return false;
    }
    try {
      final row = await remote
          .from('profiles')
          .select('is_private')
          .eq('id', profileId)
          .maybeSingle();
      return row?['is_private'] == true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> deleteCurrentProfile() async {
    final remote = client;
    final userId = remote?.auth.currentUser?.id;
    if (remote == null || userId == null) {
      return;
    }

    try {
      await remote.rpc('delete_current_user_for_app');
    } catch (error) {
      throw RepositoryFailure(
        'تعذر حذف الحساب بالكامل. طبّق آخر تحديثات قاعدة البيانات ثم حاول مرة أخرى.',
        error,
      );
    }
    _cache.clear();
    _networkCaches.clear();
    _incomingRequestsCache.clear();
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
      if (viewerType == AccountType.admin ||
          (viewerType == AccountType.company && companies)) {
        throw const FormatException('Use direct network query');
      }
      final rows = await remote.rpc<List<dynamic>>(
        'get_network_profiles_for_app',
        params: {
          'p_audience': companies ? 'companies' : 'people',
          'p_limit': _networkPageSize,
        },
      );
      final people = [
        for (var i = 0; i < rows.length; i++)
          _networkPersonFromRow(
            Map<String, dynamic>.from(rows[i] as Map),
            colorIndex: i,
          ),
      ];
      if (people.isEmpty) {
        throw const FormatException('Fallback to direct network query');
      }
      return _withRelationshipStatuses(people);
    } catch (_) {
      try {
        var query = remote
            .from('profiles')
            .select(
              'id,full_name,username,role,governorate,bio,experience_years,projects_count,followers_count,avatar_url,is_verified',
            );
        final currentProfileId = await _currentProfileId(remote);

        if (companies) {
          if (viewerType != AccountType.engineer &&
              viewerType != AccountType.company &&
              viewerType != AccountType.admin) {
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
            AccountType.admin => query.inFilter('role', const [
              'engineer',
              'contractor',
              'client',
              'craftsman',
              'worker',
              'machinery',
              'admin',
            ]),
            AccountType.craftsman ||
            AccountType.worker ||
            AccountType.equipment => query.eq('role', '__none__'),
          };
        }

        final rows = await query
            .order('is_verified', ascending: false)
            .order('projects_count', ascending: false)
            .limit(_networkPageSize);
        final people = [
          for (var i = 0; i < rows.length; i++)
            if ('${(rows[i] as Map)['id'] ?? ''}' != currentProfileId)
              _networkPersonFromRow(
                Map<String, dynamic>.from(rows[i] as Map),
                colorIndex: i,
              ),
        ];
        return _withRelationshipStatuses(people);
      } catch (_) {
        return const [];
      }
    }
  }

  @override
  Future<List<NetworkPerson>> searchPeople(String query) async {
    final remote = client;
    final term = _sanitizeSearchTerm(query);
    if (remote == null || term.isEmpty) {
      return const [];
    }
    try {
      final pattern = '%$term%';
      final currentProfileId = await _currentProfileId(remote);
      final rows = await remote
          .from('profiles')
          .select(
            'id,full_name,username,role,governorate,bio,experience_years,projects_count,followers_count,avatar_url,is_verified',
          )
          .or('full_name.ilike.$pattern,username.ilike.$pattern,bio.ilike.$pattern')
          .order('is_verified', ascending: false)
          .limit(_searchPageSize);
      return [
        for (var i = 0; i < rows.length; i++)
          if ('${(rows[i] as Map)['id'] ?? ''}' != currentProfileId)
            _networkPersonFromRow(
              Map<String, dynamic>.from(rows[i] as Map),
              colorIndex: i,
            ),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// Strips SQL `LIKE` wildcards (`%`, `_`) and PostgREST `or()` structural
  /// characters (`,`, `(`, `)`) from raw user input so a query can't break the
  /// filter syntax or inject unintended wildcards.
  String _sanitizeSearchTerm(String query) =>
      query.replaceAll(RegExp(r'[%_,()]'), ' ').trim();

  ProfileForm _profileFormFromRow(Map<String, dynamic> row) {
    final fullName = '${row['full_name'] ?? ''}'.trim();
    final parts = fullName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final firstName = parts.isEmpty ? '' : parts.first;
    final lastName = parts.length <= 1 ? '' : parts.skip(1).join(' ');
    final type = accountTypeFromSupabaseRole('${row['role'] ?? ''}');
    final location = governorateFromSupabase('${row['governorate'] ?? ''}');
    final bio = '${row['bio'] ?? ''}'.trim();
    final skills = _stringSetFrom(row['skills']);

    return ProfileForm(
      id: row['id'] == null ? null : '${row['id']}',
      avatarUrl: row['avatar_url'] == null ? null : '${row['avatar_url']}',
      coverUrl: row['cover_url'] == null ? null : '${row['cover_url']}',
      followersCount: _intFrom(row['followers_count']),
      followingCount: _intFrom(row['following_count']),
      connectionsCount: _intFrom(row['connections_count']),
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
      skills: skills,
      languages: const {},
      openToWork: type != AccountType.company,
      profilePublic: !(row['is_private'] == true),
      jobAlerts: false,
    );
  }

  int _intFrom(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }

  Set<String> _stringSetFrom(Object? value) {
    if (value is Iterable) {
      return {
        for (final item in value)
          if ('$item'.trim().isNotEmpty) '$item'.trim(),
      };
    }
    if (value is String && value.trim().isNotEmpty) {
      return {
        for (final item in value.split(RegExp(r'[,،]')))
          if (item.trim().isNotEmpty) item.trim(),
      };
    }
    return const <String>{};
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
          .limit(_incomingRequestsPageSize);
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
  Future<List<NetworkPerson>> fetchMyFollowers({bool forceRefresh = false}) {
    return _followersCache.read(_fetchMyFollowers, forceRefresh: forceRefresh);
  }

  Future<List<NetworkPerson>> _fetchMyFollowers() async {
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
          .from('followers')
          .select(
            'created_at,follower_id,profiles!followers_follower_id_fkey(id,full_name,username,role,governorate,bio,experience_years,projects_count,followers_count,avatar_url,is_verified)',
          )
          .eq('following_id', profileId)
          .order('created_at', ascending: false)
          .limit(_networkPageSize);
      return [
        for (var i = 0; i < rows.length; i++)
          _personFromJoinedRow(
            Map<String, dynamic>.from(rows[i] as Map),
            colorIndex: i,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<NetworkPerson>> fetchMyFollowing({bool forceRefresh = false}) {
    return _followingCache.read(_fetchMyFollowing, forceRefresh: forceRefresh);
  }

  Future<List<NetworkPerson>> _fetchMyFollowing() async {
    final remote = client;
    if (remote == null) {
      return const [];
    }
    final profileId = await _currentProfileId(remote);
    if (profileId == null) {
      return const [];
    }
    // Attempt 1 — single embedded select using the named FK. Works on
    // deployments where PostgREST exposes the FK relationship and the user
    // can read the joined profile row through RLS.
    try {
      final rows = await remote
          .from('followers')
          .select(
            'created_at,following_id,profiles!followers_following_id_fkey(id,full_name,username,role,governorate,bio,experience_years,projects_count,followers_count,avatar_url,is_verified)',
          )
          .eq('follower_id', profileId)
          .order('created_at', ascending: false)
          .limit(_networkPageSize);
      final list = <NetworkPerson>[];
      for (var i = 0; i < rows.length; i++) {
        final person = _markFollowed(_personFromJoinedRow(
          Map<String, dynamic>.from(rows[i] as Map),
          colorIndex: i,
        ));
        if (person.id.isNotEmpty) {
          list.add(person);
        }
      }
      if (list.isNotEmpty) {
        return list;
      }
    } catch (_) {
      // Fall through to the two-query fallback.
    }
    // Attempt 2 — two-query fallback for older schemas / strict RLS:
    // pull followed ids first, then resolve each profile separately.
    try {
      final followRows = await remote
          .from('followers')
          .select('following_id,created_at')
          .eq('follower_id', profileId)
          .order('created_at', ascending: false)
          .limit(_networkPageSize);
      final followedIds = <String>[
        for (final raw in followRows)
          '${(raw as Map)['following_id'] ?? ''}',
      ]..removeWhere((id) => id.isEmpty);
      if (followedIds.isEmpty) {
        return const [];
      }
      final profileRows = await remote
          .from('profiles')
          .select(
            'id,full_name,username,role,governorate,bio,experience_years,projects_count,followers_count,avatar_url,is_verified',
          )
          .inFilter('id', followedIds);
      // Preserve the ordering we got from the followers query.
      final byId = <String, Map<String, dynamic>>{
        for (final raw in profileRows)
          '${(raw as Map)['id'] ?? ''}':
              Map<String, dynamic>.from(raw as Map),
      };
      final list = <NetworkPerson>[];
      for (var i = 0; i < followedIds.length; i++) {
        final profileRow = byId[followedIds[i]];
        if (profileRow == null) {
          continue;
        }
        list.add(_markFollowed(
          _networkPersonFromRow(profileRow, colorIndex: i),
        ));
      }
      return list;
    } catch (_) {
      return const [];
    }
  }

  NetworkPerson _markFollowed(NetworkPerson person) {
    return NetworkPerson(
      id: person.id,
      profileId: person.profileId,
      name: person.name,
      title: person.title,
      color: person.color,
      badge: person.badge,
      contextLine: person.contextLine,
      actionLabel: 'متابَع',
      isCompany: person.isCompany,
      avatarUrl: person.avatarUrl,
      connectionStatus: person.connectionStatus,
      isFollowed: true,
    );
  }

  @override
  Future<List<NetworkPerson>> fetchMyConnections({bool forceRefresh = false}) {
    return _connectionsCache.read(
      _fetchMyConnections,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<NetworkPerson>> _fetchMyConnections() async {
    final remote = client;
    if (remote == null) {
      return const [];
    }
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return const [];
      }
      // Connection rows can be either direction (I requested OR I received).
      // Pull both directions concurrently, then take the *other party* on each
      // row. The two queries are independent, so run them in parallel.
      final results = await Future.wait([
        remote
            .from('connection_requests')
            .select(
              'updated_at,receiver_profile_id,profiles!connection_requests_receiver_profile_id_fkey(id,full_name,username,role,governorate,bio,experience_years,projects_count,followers_count,avatar_url,is_verified)',
            )
            .eq('requester_profile_id', profileId)
            .eq('status', 'accepted')
            .order('updated_at', ascending: false)
            .limit(_networkPageSize),
        remote
            .from('connection_requests')
            .select(
              'updated_at,requester_profile_id,profiles!connection_requests_requester_profile_id_fkey(id,full_name,username,role,governorate,bio,experience_years,projects_count,followers_count,avatar_url,is_verified)',
            )
            .eq('receiver_profile_id', profileId)
            .eq('status', 'accepted')
            .order('updated_at', ascending: false)
            .limit(_networkPageSize),
      ]);
      final requestedRows = results[0];
      final receivedRows = results[1];
      final all = <NetworkPerson>[];
      final seen = <String>{};
      var colorIndex = 0;
      for (final row in [...requestedRows, ...receivedRows]) {
        final person = _personFromJoinedRow(
          Map<String, dynamic>.from(row as Map),
          colorIndex: colorIndex++,
          connectionStatus: 'accepted',
        );
        if (person.id.isEmpty || !seen.add(person.id)) {
          continue;
        }
        all.add(person);
      }
      return all;
    } catch (_) {
      return const [];
    }
  }

  NetworkPerson _personFromJoinedRow(
    Map<String, dynamic> row, {
    required int colorIndex,
    String connectionStatus = 'none',
  }) {
    final profile = row['profiles'] is Map
        ? Map<String, dynamic>.from(row['profiles'] as Map)
        : <String, dynamic>{};
    final id = '${profile['id'] ?? ''}';
    final name = '${profile['full_name'] ?? 'مستخدم'}'.trim();
    final role = '${profile['role'] ?? ''}';
    final governorate = '${profile['governorate'] ?? ''}';
    final bio = '${profile['bio'] ?? ''}'.trim();
    final isCompany = role == 'contractor' || role == 'client';
    final colors = [
      AppColors.blue,
      AppColors.darkBlue,
      AppColors.muted,
      AppColors.black,
    ];
    return NetworkPerson(
      id: id,
      profileId: id,
      name: name.isEmpty ? 'مستخدم' : name,
      title: _titleForRole(role, governorate, bio),
      color: colors[colorIndex % colors.length],
      badge: profile['is_verified'] == true ? 'موثق' : null,
      contextLine: governorate.isEmpty ? 'مهني' : governorate,
      actionLabel: connectionStatus == 'accepted' ? 'متصل' : 'تواصل',
      isCompany: isCompany,
      avatarUrl: profile['avatar_url'] == null
          ? null
          : '${profile['avatar_url']}',
      connectionStatus: connectionStatus,
    );
  }

  String _titleForRole(String role, String governorate, String bio) {
    if (bio.isNotEmpty) {
      return bio;
    }
    final label = switch (role) {
      'engineer' => 'مهندس',
      'contractor' => 'شركة مقاولات',
      'client' => 'صاحب مشروع',
      'craftsman' => 'حرفي',
      'worker' => 'عامل',
      'machinery' => 'مزود آليات',
      'admin' => 'إدارة',
      _ => 'مهني',
    };
    return governorate.isEmpty ? label : '$label · $governorate';
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
      // Server-side `app_notify_on_connection_request` trigger handles
      // the notification. No client insert here to avoid duplicates.
      _networkCaches.clear();
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
        // Trigger fires on this insert too.
        _networkCaches.clear();
      } catch (_) {
        // Connection request remains optimistic in the UI.
      }
    }
  }

  @override
  Future<String> connectionStatus(String otherProfileId) async {
    final remote = client;
    if (remote == null || otherProfileId.isEmpty) {
      return 'none';
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null || profileId == otherProfileId) {
        return 'none';
      }
      final row = await remote
          .from('connection_requests')
          .select('status,requester_profile_id,receiver_profile_id')
          .or(
            'and(requester_profile_id.eq.$profileId,receiver_profile_id.eq.$otherProfileId),and(requester_profile_id.eq.$otherProfileId,receiver_profile_id.eq.$profileId)',
          )
          .maybeSingle();
      return row == null ? 'none' : '${row['status'] ?? 'none'}';
    } catch (_) {
      return 'none';
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
      _followingCache.clear();
    } catch (_) {
      // Follow stays best-effort when the optional relation is unavailable.
    }
  }

  @override
  Future<void> unfollowProfile(String followingProfileId) async {
    final remote = client;
    if (remote == null || followingProfileId.isEmpty) {
      return;
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null || profileId == followingProfileId) {
        return;
      }
      await remote
          .from('followers')
          .delete()
          .eq('follower_id', profileId)
          .eq('following_id', followingProfileId);
      _networkCaches.clear();
      _followingCache.clear();
    } catch (_) {
      // Unfollow stays best-effort when the optional relation is unavailable.
    }
  }

  @override
  Future<bool> isFollowingProfile(String followingProfileId) async {
    final remote = client;
    if (remote == null || followingProfileId.isEmpty) {
      return false;
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null || profileId == followingProfileId) {
        return false;
      }
      final row = await remote
          .from('followers')
          .select('id')
          .eq('follower_id', profileId)
          .eq('following_id', followingProfileId)
          .maybeSingle();
      return row != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ProfileStats> fetchProfileStats(String profileId) async {
    final remote = client;
    if (remote == null || profileId.isEmpty) {
      return ProfileStats.empty;
    }
    int followers = 0;
    int following = 0;
    int connections = 0;
    try {
      final row = await remote
          .from('profiles')
          .select('followers_count,following_count,connections_count')
          .eq('id', profileId)
          .maybeSingle();
      if (row != null) {
        followers = _intFrom(row['followers_count']);
        following = _intFrom(row['following_count']);
        connections = _intFrom(row['connections_count']);
      }
    } catch (_) {
      // Counts columns may be missing — fall through to per-table counts.
    }
    if (followers == 0) {
      try {
        final rows = await remote
            .from('followers')
            .select('id')
            .eq('following_id', profileId);
        followers = rows.length;
      } catch (_) {
        // Followers table is optional in older deployments.
      }
    }
    if (following == 0) {
      try {
        final rows = await remote
            .from('followers')
            .select('id')
            .eq('follower_id', profileId);
        following = rows.length;
      } catch (_) {
        // Followers table is optional in older deployments.
      }
    }
    if (connections == 0) {
      try {
        final counts = await Future.wait([
          remote
              .from('connection_requests')
              .select('id')
              .eq('requester_profile_id', profileId)
              .eq('status', 'accepted'),
          remote
              .from('connection_requests')
              .select('id')
              .eq('receiver_profile_id', profileId)
              .eq('status', 'accepted'),
        ]);
        connections = counts[0].length + counts[1].length;
      } catch (_) {
        // connection_requests table is optional in older deployments.
      }
    }
    return ProfileStats(
      followers: followers,
      following: following,
      connections: connections,
    );
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
      if (accept) {
        await _createConversationForAcceptedRequest(remote, requestId);
        // The trigger fires on UPDATE status='accepted' and emits the
        // Arabic notification. No client insert needed.
      }
      _incomingRequestsCache.clear();
      _networkCaches.clear();
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
      avatarUrl: person.avatarUrl,
      connectionStatus: person.connectionStatus,
      isFollowed: person.isFollowed,
    );
  }

  Future<String?> _currentProfileId(SupabaseClient remote) =>
      CurrentProfileResolver.instance.resolve(client: remote);

  bool _canViewNetwork(AccountType viewerType) {
    return viewerType == AccountType.engineer ||
        viewerType == AccountType.company ||
        viewerType == AccountType.admin;
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
      avatarUrl: row['avatar_url'] == null ? null : '${row['avatar_url']}',
    );
  }

  Future<void> _createConversationForAcceptedRequest(
    SupabaseClient remote,
    String requestId,
  ) async {
    try {
      final row = await remote
          .from('connection_requests')
          .select('requester_profile_id,receiver_profile_id')
          .eq('id', requestId)
          .maybeSingle();
      if (row == null) {
        return;
      }
      final requester = '${row['requester_profile_id'] ?? ''}';
      final receiver = '${row['receiver_profile_id'] ?? ''}';
      if (requester.isEmpty || receiver.isEmpty) {
        return;
      }
      final ordered = requester.compareTo(receiver) <= 0
          ? (requester, receiver)
          : (receiver, requester);
      await remote.from('conversations').upsert({
        'participant_one': ordered.$1,
        'participant_two': ordered.$2,
        'last_message_at': DateTime.now().toIso8601String(),
      }, onConflict: 'participant_one,participant_two');
    } catch (_) {
      // Accepted connections still appear in messages through connection requests.
    }
  }

  Future<List<NetworkPerson>> _withRelationshipStatuses(
    List<NetworkPerson> people,
  ) async {
    final remote = client;
    if (remote == null || people.isEmpty) {
      return people;
    }
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return people;
      }
      final ids = people.map((person) => person.id).toSet();
      final connectionRows = await remote
          .from('connection_requests')
          .select('requester_profile_id,receiver_profile_id,status')
          .or(
            'requester_profile_id.eq.$profileId,receiver_profile_id.eq.$profileId',
          );
      final statuses = <String, String>{};
      for (final raw in connectionRows) {
        final row = Map<String, dynamic>.from(raw as Map);
        final requester = '${row['requester_profile_id'] ?? ''}';
        final receiver = '${row['receiver_profile_id'] ?? ''}';
        final other = requester == profileId ? receiver : requester;
        if (ids.contains(other)) {
          statuses[other] = '${row['status'] ?? 'none'}';
        }
      }
      final followRows = await remote
          .from('followers')
          .select('following_id')
          .eq('follower_id', profileId)
          .inFilter('following_id', ids.toList());
      final followedIds = {
        for (final raw in followRows) '${(raw as Map)['following_id'] ?? ''}',
      }..remove('');
      return [
        for (final person in people)
          if ((statuses[person.id] ?? person.connectionStatus) != 'accepted')
            _personWithRelationship(
              person,
              statuses[person.id] ?? person.connectionStatus,
              followedIds.contains(person.id),
            ),
      ];
    } catch (_) {
      return people;
    }
  }

  NetworkPerson _personWithRelationship(
    NetworkPerson person,
    String status,
    bool isFollowed,
  ) {
    final normalized = status == 'accepted' || status == 'pending'
        ? status
        : 'none';
    return NetworkPerson(
      id: person.id,
      profileId: person.profileId,
      name: person.name,
      title: person.title,
      color: person.color,
      badge: person.badge,
      contextLine: person.contextLine,
      actionLabel: switch (normalized) {
        'accepted' => 'متصل',
        'pending' => 'قيد الانتظار',
        _ when isFollowed => 'متابَع',
        _ => person.actionLabel,
      },
      isCompany: person.isCompany,
      avatarUrl: person.avatarUrl,
      connectionStatus: normalized,
      isFollowed: isFollowed,
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
      AccountType.admin => 'إدارة المنصة',
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
