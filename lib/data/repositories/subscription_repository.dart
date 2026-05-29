import 'package:supabase_flutter/supabase_flutter.dart';

import '../session/current_profile_resolver.dart';

import 'repository_failure.dart';

abstract interface class SubscriptionRepository {
  Future<bool> hasActiveSubscription();

  Future<PremiumCheckout> createPremiumCheckout({num amount = 120000});

  Future<void> verifyPremiumCheckout(PremiumCheckout checkout);
}

final class PremiumCheckout {
  const PremiumCheckout({
    required this.checkoutId,
    required this.paymentUrl,
    required this.paymentWidgetUrl,
    required this.paymentResultUrl,
    required this.profileId,
  });

  final String checkoutId;
  final Uri paymentUrl;
  final Uri paymentWidgetUrl;
  final Uri paymentResultUrl;
  final String profileId;
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
  Future<PremiumCheckout> createPremiumCheckout({num amount = 120000}) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure('بوابة الدفع غير مهيأة الآن');
    }

    try {
      final userId = remote.auth.currentUser?.id;
      if (userId == null) {
        throw const RepositoryFailure('سجل الدخول أولا');
      }

      // Read the owner's own contact details. Prefer the SECURITY DEFINER
      // `get_my_profile` RPC since email/phone are no longer granted to
      // `authenticated` for direct table reads (see profile_contact_privacy
      // migration); fall back to a direct select on older backends.
      Map<String, dynamic>? profile;
      try {
        final result = await remote.rpc('get_my_profile');
        if (result is List && result.isNotEmpty && result.first is Map) {
          profile = Map<String, dynamic>.from(result.first as Map);
        } else if (result is Map) {
          profile = Map<String, dynamic>.from(result);
        }
      } catch (_) {
        // RPC unavailable — fall through to the legacy direct read.
      }
      profile ??= await remote
          .from('profiles')
          .select('id, full_name, email, phone')
          .eq('user_id', userId)
          .maybeSingle();
      final profileId = profile == null ? null : '${profile['id']}';
      if (profileId == null || profileId.isEmpty) {
        throw const RepositoryFailure('تعذر العثور على ملفك الشخصي');
      }

      final accessToken = await _currentAccessToken(remote);
      if (accessToken == null || accessToken.isEmpty) {
        throw const RepositoryFailure(
          'انتهت جلسة الدخول. سجل الدخول مرة أخرى.',
        );
      }
      final response = await remote.functions.invoke(
        'switch-payment',
        headers: {
          'Authorization': 'Bearer $accessToken',
          'x-customer-auth': 'Bearer $accessToken',
        },
        body: {
          'action': 'create-checkout',
          'amount': amount,
          'orderId':
              'premium_${profileId}_${DateTime.now().millisecondsSinceEpoch}',
          'profileId': profileId,
          'customerName': '${profile?['full_name'] ?? ''}',
          'customerPhone': '${profile?['phone'] ?? ''}',
          if ('${profile?['email'] ?? ''}'.contains('@'))
            'customerEmail': '${profile?['email']}',
        },
      );
      final data = response.data;
      if (data is Map &&
          data['success'] == true &&
          data['checkoutId'] != null) {
        final checkoutId = '${data['checkoutId']}';
        final checkoutProfileId = '${data['profileId'] ?? profileId}';
        final paymentUrl = Uri.tryParse('${data['paymentUrl'] ?? ''}');
        if (paymentUrl == null || !paymentUrl.hasScheme) {
          throw const RepositoryFailure('تعذر تجهيز صفحة الدفع الآن');
        }
        final paymentWidgetUrl = Uri.tryParse(
          '${data['paymentWidgetUrl'] ?? ''}',
        );
        final paymentResultUrl = Uri.tryParse(
          '${data['paymentResultUrl'] ?? ''}',
        );
        if (paymentWidgetUrl == null ||
            !paymentWidgetUrl.hasScheme ||
            paymentResultUrl == null ||
            !paymentResultUrl.hasScheme) {
          throw const RepositoryFailure('تعذر تجهيز صفحة الدفع الآن');
        }
        return PremiumCheckout(
          checkoutId: checkoutId,
          paymentUrl: paymentUrl,
          paymentWidgetUrl: paymentWidgetUrl,
          paymentResultUrl: paymentResultUrl,
          profileId: checkoutProfileId,
        );
      }
      if (data is Map && (data['error'] != null || data['message'] != null)) {
        throw RepositoryFailure('${data['error'] ?? data['message']}');
      }
      throw const RepositoryFailure('تعذر إنشاء طلب الدفع الآن');
    } catch (error) {
      if (error is RepositoryFailure) {
        rethrow;
      }
      final message = _functionErrorMessage(error);
      if (message != null) {
        throw RepositoryFailure(message, error);
      }
      throw RepositoryFailure('تعذر إنشاء طلب الدفع الآن', error);
    }
  }

  @override
  Future<void> verifyPremiumCheckout(PremiumCheckout checkout) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure('بوابة الدفع غير مهيأة الآن');
    }

    try {
      final accessToken = await _currentAccessToken(remote);
      if (accessToken == null || accessToken.isEmpty) {
        throw const RepositoryFailure(
          'انتهت جلسة الدخول. سجل الدخول مرة أخرى.',
        );
      }
      final response = await remote.functions.invoke(
        'switch-payment',
        headers: {
          'Authorization': 'Bearer $accessToken',
          'x-customer-auth': 'Bearer $accessToken',
        },
        body: {
          'action': 'verify-and-activate',
          'checkoutId': checkout.checkoutId,
          'profileId': checkout.profileId,
        },
      );
      final data = response.data;
      if (data is Map && data['success'] == true) {
        return;
      }
      if (data is Map && (data['error'] != null || data['message'] != null)) {
        throw RepositoryFailure('${data['error'] ?? data['message']}');
      }
      throw const RepositoryFailure('لم يتم تأكيد الدفع بعد');
    } catch (error) {
      if (error is RepositoryFailure) {
        rethrow;
      }
      final message = _functionErrorMessage(error);
      if (message != null) {
        throw RepositoryFailure(message, error);
      }
      throw RepositoryFailure('تعذر تأكيد الدفع الآن', error);
    }
  }

  Future<String?> _currentProfileId(SupabaseClient remote) =>
      CurrentProfileResolver.instance.resolve(client: remote);

  Future<String?> _currentAccessToken(SupabaseClient remote) async {
    final currentSession = remote.auth.currentSession;
    if (currentSession != null &&
        !currentSession.isExpired &&
        currentSession.accessToken.isNotEmpty) {
      return currentSession.accessToken;
    }
    try {
      final refreshed = await remote.auth.refreshSession();
      final refreshedToken = refreshed.session?.accessToken;
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        return refreshedToken;
      }
    } catch (_) {
      // The caller will surface a sign-in prompt if no valid token remains.
    }
    final fallbackSession = remote.auth.currentSession;
    if (fallbackSession != null &&
        !fallbackSession.isExpired &&
        fallbackSession.accessToken.isNotEmpty) {
      return fallbackSession.accessToken;
    }
    return null;
  }

  String? _functionErrorMessage(Object error) {
    if (error is! FunctionException) {
      return null;
    }
    final detailsMessage = _functionDetailsMessage(error.details);
    if (detailsMessage != null) {
      return detailsMessage;
    }
    if (error.status == 401) {
      return 'انتهت جلسة الدخول. سجل الدخول مرة أخرى.';
    }
    return null;
  }

  String? _functionDetailsMessage(Object? details) {
    if (details is Map) {
      final message = details['message'] ?? details['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
      final nested = details['details'];
      if (nested is Map) {
        final result = nested['result'];
        if (result is Map) {
          final description = result['description'];
          final code = result['code'];
          if (description is String && description.trim().isNotEmpty) {
            return code == null
                ? 'تعذر إنشاء طلب الدفع: ${description.trim()}'
                : 'تعذر إنشاء طلب الدفع: ${description.trim()} ($code)';
          }
        }
      }
    }
    return null;
  }
}
