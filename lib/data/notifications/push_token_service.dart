import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'local_notification_service.dart';

/// Registers the device's FCM token (Android / iOS / Web) into `device_tokens`
/// so the `send-push` edge function can deliver background pushes, and wires
/// foreground messages into [LocalNotificationService].
///
/// Web background push additionally needs the project's Web Push VAPID public
/// key. Provide it at build time with
/// `--dart-define=FCM_VAPID_KEY=<public key>`. Without it, web still receives
/// foreground notifications; only web *background* push is skipped.
class PushTokenService {
  static const String _webVapidKey = String.fromEnvironment('FCM_VAPID_KEY');
  static bool _wired = false;

  /// Best-effort: requests permission, stores the token, wires listeners.
  /// Never throws — push must not block sign-in.
  static Future<void> register() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      if (!_wired) {
        _wired = true;
        FirebaseMessaging.onMessage.listen((message) {
          final notification = message.notification;
          LocalNotificationService.instance.show(
            title:
                notification?.title ?? message.data['title'] ?? 'إشعار جديد',
            body: notification?.body ?? message.data['body'] ?? '',
          );
        });
        messaging.onTokenRefresh.listen(_storeToken);
      }

      if (kIsWeb && _webVapidKey.isEmpty) {
        // No VAPID key → skip web background token, foreground still works.
        return;
      }
      final token = kIsWeb
          ? await messaging.getToken(vapidKey: _webVapidKey)
          : await messaging.getToken();
      await _storeToken(token);
    } catch (_) {
      // Push is a best-effort enhancement.
    }
  }

  static Future<void> _storeToken(String? token) async {
    if (token == null || token.isEmpty) {
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      await Supabase.instance.client.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      }, onConflict: 'token');
    } catch (_) {
      // Token storage is best-effort.
    }
  }

  /// Drops this device's token on sign-out so the user stops receiving pushes.
  static Future<void> unregister() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        return;
      }
      await Supabase.instance.client
          .from('device_tokens')
          .delete()
          .eq('token', token);
    } catch (_) {
      // Best-effort.
    }
  }
}
