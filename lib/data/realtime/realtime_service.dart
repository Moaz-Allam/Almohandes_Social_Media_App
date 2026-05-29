import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/async/debouncer.dart';
import '../session/current_profile_resolver.dart';

/// Subscribes to Supabase Realtime `postgres_changes` for the signed-in user
/// so messages and notifications update live, without polling.
///
/// We translate raw row events into two coarse callbacks. The existing
/// repositories then re-query (with their short caches bypassed) when the UI
/// reacts to the version bump — this keeps the streaming layer tiny and reuses
/// all the existing fetch/merge logic instead of re-implementing it over a
/// stream.
class RealtimeService {
  RealtimeService({
    required this.client,
    Duration debounce = const Duration(milliseconds: 400),
  }) : _messagesDebouncer = Debouncer(debounce),
       _notificationsDebouncer = Debouncer(debounce);

  final SupabaseClient? client;

  // A single chat or notification action can emit several `postgres_changes`
  // rows in quick succession (e.g. an INSERT into `messages` plus an UPDATE of
  // the parent `conversations` row, or a batch of notification inserts). These
  // debouncers collapse such bursts into one coarse callback so the UI refetches
  // each list once instead of once per row.
  final Debouncer _messagesDebouncer;
  final Debouncer _notificationsDebouncer;

  RealtimeChannel? _channel;
  bool _starting = false;
  void Function()? _onMessages;
  void Function(Map<String, dynamic> row)? _onMessageRow;
  void Function(Map<String, dynamic>? latest)? _onNotifications;

  /// Opens the realtime channel. Safe to call repeatedly — a no-op if a
  /// channel is already open or one is being set up. Never throws: realtime is
  /// a live-update nicety and must not break the app if it fails to connect.
  ///
  /// [onMessageRow] receives each inserted `messages` row immediately (it is
  /// deliberately NOT debounced, so an open chat can append every new row
  /// without dropping any in a burst). [onMessagesChanged] stays debounced and
  /// drives the coarse conversations-list refresh.
  Future<void> start({
    required void Function() onMessagesChanged,
    required void Function(Map<String, dynamic> row) onMessageRow,
    required void Function(Map<String, dynamic>? latest) onNotificationsChanged,
  }) async {
    final remote = client;
    if (remote == null || _channel != null || _starting) {
      return;
    }
    _starting = true;
    _onMessages = onMessagesChanged;
    _onMessageRow = onMessageRow;
    _onNotifications = onNotificationsChanged;
    try {
      final profileId = await CurrentProfileResolver.instance.resolve(
        client: remote,
      );
      final channel = remote.channel('public:app-realtime');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'messages',
            callback: (payload) {
              // Immediate, un-debounced per-row delivery so an open chat can
              // append the exact new message (a debounce would collapse a
              // burst and drop all but the last row).
              if (payload.eventType == PostgresChangeEvent.insert) {
                final record = payload.newRecord;
                if (record.isNotEmpty) {
                  _onMessageRow?.call(Map<String, dynamic>.from(record));
                }
              }
              // Coarse, debounced signal for the conversations list (preview +
              // unread counts).
              _messagesDebouncer(() => _onMessages?.call());
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'conversations',
            callback: (_) => _messagesDebouncer(() => _onMessages?.call()),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            filter: profileId == null
                ? null
                : PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'profile_id',
                    value: profileId,
                  ),
            callback: (payload) {
              final record = payload.newRecord;
              final latest = record.isEmpty
                  ? null
                  : Map<String, dynamic>.from(record);
              _notificationsDebouncer(() => _onNotifications?.call(latest));
            },
          )
          .subscribe();
      _channel = channel;
    } catch (_) {
      // Swallow — the app stays fully functional via manual refresh.
    } finally {
      _starting = false;
    }
  }

  /// Tears the channel down (on sign-out / dispose). Best-effort.
  Future<void> stop() async {
    final channel = _channel;
    _channel = null;
    _onMessages = null;
    _onMessageRow = null;
    _onNotifications = null;
    _messagesDebouncer.cancel();
    _notificationsDebouncer.cancel();
    if (channel != null) {
      try {
        await client?.removeChannel(channel);
      } catch (_) {
        // Best-effort teardown.
      }
    }
  }
}
