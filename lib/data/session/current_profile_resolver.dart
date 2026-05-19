import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves the public.profiles.id for the signed-in user and memoizes it.
///
/// Every interaction (like, repost, save, comment, upload …) used to do its
/// own `select id from profiles where user_id = ?` round-trip, which is a
/// huge tax on a slow connection. We cache it per `auth.uid()` and listen
/// to auth state changes to invalidate.
final class CurrentProfileResolver {
  CurrentProfileResolver(this._client) {
    final client = _client;
    if (client != null) {
      _authSub = client.auth.onAuthStateChange.listen((event) {
        if (event.event == AuthChangeEvent.signedOut) {
          _cachedProfileId = null;
          _cachedForUserId = null;
        }
      });
    }
  }

  static final CurrentProfileResolver _shared = CurrentProfileResolver(
    _tryClient(),
  );

  static CurrentProfileResolver get instance => _shared;

  static SupabaseClient? _tryClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  final SupabaseClient? _client;
  String? _cachedProfileId;
  String? _cachedForUserId;
  // Keyed by userId so two concurrent requests for the same user share one
  // lookup, but a sign-out / sign-in mid-flight starts a fresh request.
  final Map<String, Future<String?>> _pending = <String, Future<String?>>{};

  // ignore: unused_field
  Object? _authSub;

  Future<String?> resolve({SupabaseClient? client}) async {
    final remote = client ?? _client;
    if (remote == null) {
      return null;
    }
    final userId = remote.auth.currentUser?.id;
    if (userId == null) {
      _cachedProfileId = null;
      _cachedForUserId = null;
      return null;
    }
    if (_cachedForUserId == userId && _cachedProfileId != null) {
      return _cachedProfileId;
    }
    final existing = _pending[userId];
    if (existing != null) {
      return existing;
    }
    final future = _lookup(remote, userId);
    _pending[userId] = future;
    try {
      final result = await future;
      // Only cache if the current auth user hasn't changed since we kicked off.
      if (remote.auth.currentUser?.id == userId) {
        _cachedProfileId = result;
        _cachedForUserId = userId;
      }
      return result;
    } finally {
      _pending.remove(userId);
    }
  }

  void invalidate() {
    _cachedProfileId = null;
    _cachedForUserId = null;
  }

  Future<String?> _lookup(SupabaseClient remote, String userId) async {
    try {
      final row = await remote
          .from('profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      return '${row['id']}';
    } catch (_) {
      return null;
    }
  }
}
