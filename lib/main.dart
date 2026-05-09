import 'dart:ui';

import 'package:flutter/material.dart';

import 'app/linked_arabic_app.dart';
import 'data/supabase/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(const LinkedArabicApp());
}
