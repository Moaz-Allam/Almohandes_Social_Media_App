final class SupabaseConfig {
  const SupabaseConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  static const url = String.fromEnvironment('SUPABASE_URL');
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get isConfigured {
    return url.isNotEmpty && publishableKey.isNotEmpty;
  }

  static SupabaseConfig? fromEnvironment() {
    if (!isConfigured) {
      return null;
    }
    return const SupabaseConfig(
      supabaseUrl: url,
      supabasePublishableKey: publishableKey,
    );
  }

  final String supabaseUrl;
  final String supabasePublishableKey;
}
