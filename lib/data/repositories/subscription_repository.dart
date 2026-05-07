import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class SubscriptionRepository {
  Future<bool> hasActiveSubscription();

  Future<void> activateCurrentUser();
}

final class SupabaseSubscriptionRepository implements SubscriptionRepository {
  SupabaseSubscriptionRepository({required this.client});

  final SupabaseClient? client;

  @override
  Future<bool> hasActiveSubscription() async {
    final remote = client;
    if (remote == null) {
      return false;
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return false;
      }
      final response = await remote.rpc<bool>(
        'has_active_subscription',
        params: {'p_profile_id': profileId},
      );
      return response;
    } catch (_) {
      try {
        final profileId = await _currentProfileId(remote);
        if (profileId == null) {
          return false;
        }
        final row = await remote
            .from('subscriptions')
            .select('status,expires_at')
            .eq('profile_id', profileId)
            .maybeSingle();
        return row != null && '${row['status']}' == 'active';
      } catch (_) {
        return false;
      }
    }
  }

  @override
  Future<void> activateCurrentUser() async {
    final remote = client;
    if (remote == null) {
      return;
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return;
      }
      await remote.rpc(
        'activate_subscription_p',
        params: {'p_profile_id': profileId},
      );
    } catch (_) {
      // Premium dashboard remains available locally if payment is simulated.
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
}
