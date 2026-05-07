import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

final class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static Future<void> initializeIfConfigured() async {
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
