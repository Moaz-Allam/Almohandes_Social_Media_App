import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

final class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static Future<void>? _initFuture;

  /// Idempotent. Returns the same Future across calls so consumers can
  /// await it from anywhere (e.g. AppController.bootstrap) without
  /// kicking off a second initialization.
  static Future<void> initializeIfConfigured() {
    return _initFuture ??= _doInitialize();
  }

  /// Future that resolves when Supabase is ready (or immediately if it
  /// isn't configured at all). Use from bootstrap paths to delay any
  /// authenticated query until the client exists.
  static Future<void> get ready =>
      _initFuture ?? initializeIfConfigured();

  static Future<void> _doInitialize() async {
    final config = SupabaseConfig.fromEnvironment();
    if (config == null) {
      return;
    }
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabasePublishableKey,
      debug: false,
    );
  }

  static SupabaseClient? maybeClient() {
    if (!SupabaseConfig.isConfigured) {
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
