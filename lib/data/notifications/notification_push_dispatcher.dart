import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class NotificationPushDispatcher {
  static Future<void> create(
    SupabaseClient remote,
    Map<String, Object?> notification,
  ) async {
    await remote.from('notifications').insert(notification);
  }
}
