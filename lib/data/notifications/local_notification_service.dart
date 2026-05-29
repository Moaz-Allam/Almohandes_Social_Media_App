import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows in-app / foreground OS notifications (Arabic text + the app icon)
/// driven by the realtime notification stream.
///
/// This covers the "local / in-app" channel. Background push when the app is
/// killed is handled separately by FCM (mobile) and Web Push — see
/// supabase/PUSH_SETUP.md. Every call is guarded so an unsupported platform
/// (web) or a missing plugin can never crash the app.
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const _channelId = 'almohandes_general';
  static const _channelName = 'إشعارات المهندس';
  static const _channelDescription = 'تنبيهات الرسائل والإشعارات داخل التطبيق';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    // flutter_local_notifications has no web implementation; skip it there.
    if (kIsWeb || _initialized) {
      return;
    }
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
      );
      final android0 = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      // Create the channel up front so FCM background/terminated messages
      // (which reference it via the manifest meta-data) render correctly.
      await android0?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.high,
        ),
      );
      // Ask for the Android 13+ POST_NOTIFICATIONS permission up front.
      await android0?.requestNotificationsPermission();
      _initialized = true;
    } catch (_) {
      // Leave uninitialized; show() will retry and stay silent on failure.
    }
  }

  /// Pops a heads-up notification with the app icon. No-op on web / on error.
  Future<void> show({required String title, required String body}) async {
    if (kIsWeb) {
      return;
    }
    try {
      if (!_initialized) {
        await init();
      }
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title.isEmpty ? 'إشعار جديد' : title,
        body,
        details,
      );
    } catch (_) {
      // Never let a notification failure surface to the user.
    }
  }
}
