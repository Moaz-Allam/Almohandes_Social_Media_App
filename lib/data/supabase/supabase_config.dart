final class SupabaseConfig {
  const SupabaseConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
  });

  static const url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gwuzlcmuxcokfpnaofjc.supabase.co',
  );
  static const publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3dXpsY211eGNva2ZwbmFvZmpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM2OTg0NzYsImV4cCI6MjA4OTI3NDQ3Nn0.dW6Q035utDysDTW4DaJrxYPO66dIxRG309yZBkyKzmQ',
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
