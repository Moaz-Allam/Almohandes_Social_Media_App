import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'app/linked_arabic_app.dart';
import 'data/notifications/local_notification_service.dart';
import 'data/supabase/supabase_bootstrap.dart';
import 'firebase_options.dart';

/// Background isolate entrypoint. The OS renders `notification` payloads
/// itself; this just needs to exist and be a top-level function.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Cap the in-memory image cache. Default is 1000 entries / ~100MB which
  // can OOM mid-range Android devices after scrolling long feeds. We don't
  // need that much — the disk cache (via cached_network_image) covers
  // re-fetches.
  PaintingBinding.instance.imageCache.maximumSize = 200;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
    return true;
  };
  ErrorWidget.builder = (details) => Material(
    color: const Color(0xFFF4F7FB),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'حدث خطأ غير متوقع. أعد المحاولة بعد لحظات.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    ),
  );

  await SupabaseBootstrap.initializeIfConfigured();
  // Set up local/foreground notifications (Arabic + app icon). No-op on web.
  await LocalNotificationService.instance.init();
  // Initialise Firebase for background push (FCM mobile + Web Push). Guarded
  // so a misconfiguration can never block app startup.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  } catch (_) {
    // App stays fully functional with just local notifications.
  }
  runApp(const LinkedArabicApp());
}
