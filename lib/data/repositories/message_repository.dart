import 'package:flutter/material.dart' show Color;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/message_item.dart';
import '../cache/timed_memory_cache.dart';

abstract interface class MessageRepository {
  Future<List<MessageItem>> fetchConversations({bool forceRefresh = false});

  Future<List<ChatMessage>> fetchMessages(
    String conversationId, {
    bool forceRefresh = false,
  });

  Future<void> sendMessage({
    required String conversationId,
    required String content,
  });
}

final class SupabaseMessageRepository implements MessageRepository {
  SupabaseMessageRepository({required this.client});

  final SupabaseClient? client;
  final _conversationCache = TimedMemoryCache<List<MessageItem>>(
    ttl: const Duration(seconds: 30),
  );
  final _messageCaches = <String, TimedMemoryCache<List<ChatMessage>>>{};

  @override
  Future<List<MessageItem>> fetchConversations({bool forceRefresh = false}) {
    return _conversationCache.read(
      _fetchConversations,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<MessageItem>> _fetchConversations() async {
    final remote = client;
    if (remote == null) {
      return const [];
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return const [];
      }
      final rows = await remote.rpc<List<dynamic>>(
        'get_user_conversations',
        params: {'p_profile_id': profileId},
      );
      return [
        for (var i = 0; i < rows.length; i++)
          _conversationFromRpc(
            Map<String, dynamic>.from(rows[i] as Map),
            colorIndex: i,
          ),
      ];
    } catch (_) {
      try {
        final profileId = await _currentProfileId(remote);
        if (profileId == null) {
          return const [];
        }
        final rows = await remote
            .from('conversations')
            .select()
            .or('participant_one.eq.$profileId,participant_two.eq.$profileId')
            .order('last_message_at', ascending: false)
            .limit(50);
        return [
          for (var i = 0; i < rows.length; i++)
            _conversationFromTable(
              Map<String, dynamic>.from(rows[i] as Map),
              currentProfileId: profileId,
              colorIndex: i,
            ),
        ];
      } catch (_) {
        return const [];
      }
    }
  }

  @override
  Future<List<ChatMessage>> fetchMessages(
    String conversationId, {
    bool forceRefresh = false,
  }) {
    final cache = _messageCaches.putIfAbsent(
      conversationId,
      () =>
          TimedMemoryCache<List<ChatMessage>>(ttl: const Duration(seconds: 20)),
    );
    return cache.read(
      () => _fetchMessages(conversationId),
      forceRefresh: forceRefresh,
    );
  }

  Future<List<ChatMessage>> _fetchMessages(String conversationId) async {
    final remote = client;
    if (remote == null || conversationId.isEmpty) {
      return const [];
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return const [];
      }
      final rows = await remote
          .from('messages')
          .select('id,sender_id,content,created_at')
          .eq('conversation_id', conversationId)
          .order('created_at');
      return [
        for (final row in rows)
          _messageFromRow(
            Map<String, dynamic>.from(row as Map),
            currentProfileId: profileId,
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final remote = client;
    final trimmed = content.trim();
    if (remote == null || conversationId.isEmpty || trimmed.isEmpty) {
      return;
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return;
      }
      await remote.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': profileId,
        'content': trimmed,
        'message_type': 'text',
      });
      _messageCaches[conversationId]?.clear();
      _conversationCache.clear();
    } catch (_) {
      // Message sending remains best effort if no active Supabase session exists.
    }
  }

  MessageItem _conversationFromRpc(
    Map<String, dynamic> row, {
    required int colorIndex,
  }) {
    final name =
        '${row['recipient_name'] ?? row['full_name'] ?? row['name'] ?? 'محادثة'}';
    return MessageItem(
      conversationId: '${row['conversation_id'] ?? row['id'] ?? ''}',
      profileId: row['recipient_profile_id'] == null
          ? null
          : '${row['recipient_profile_id']}',
      name: name,
      preview: '${row['last_message'] ?? ''}',
      time: _timeLabel(row['last_message_at'] ?? row['updated_at']),
      unread: _intFrom(row['unread_count']) > 0,
      color: _colorForIndex(colorIndex),
    );
  }

  MessageItem _conversationFromTable(
    Map<String, dynamic> row, {
    required String currentProfileId,
    required int colorIndex,
  }) {
    final participantOne = '${row['participant_one'] ?? ''}';
    final participantTwo = '${row['participant_two'] ?? ''}';
    final otherId = participantOne == currentProfileId
        ? participantTwo
        : participantOne;
    return MessageItem(
      conversationId: '${row['id']}',
      profileId: otherId.isEmpty ? null : otherId,
      name: 'محادثة',
      preview: '${row['last_message'] ?? ''}',
      time: _timeLabel(row['last_message_at']),
      unread: false,
      color: _colorForIndex(colorIndex),
    );
  }

  ChatMessage _messageFromRow(
    Map<String, dynamic> row, {
    required String currentProfileId,
  }) {
    return ChatMessage(
      id: '${row['id']}',
      text: '${row['content'] ?? ''}',
      incoming: '${row['sender_id']}' != currentProfileId,
      createdAt:
          DateTime.tryParse('${row['created_at']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  String _timeLabel(Object? value) {
    final date = DateTime.tryParse('$value');
    if (date == null) {
      return '';
    }
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      return 'قبل ${diff.inMinutes.clamp(1, 59)} د';
    }
    if (diff.inHours < 24) {
      return 'قبل ${diff.inHours} س';
    }
    return 'قبل ${diff.inDays} يوم';
  }

  int _intFrom(Object? value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }

  Color _colorForIndex(int index) {
    return switch (index % 4) {
      0 => AppColors.blue,
      1 => AppColors.darkBlue,
      2 => AppColors.muted,
      _ => AppColors.black,
    };
  }

  Future<String?> _currentProfileId(SupabaseClient remote) async {
    final userId = remote.auth.currentUser?.id;
    if (userId == null) {
      return null;
    }
    final row = await remote
        .from('profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    return row == null ? null : '${row['id']}';
  }
}
