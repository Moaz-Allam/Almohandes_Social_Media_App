import 'dart:async';

import 'package:flutter/material.dart' show Color;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../models/message_item.dart';
import '../cache/timed_memory_cache.dart';
import 'repository_failure.dart';

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

  Future<void> sendVoiceMessage({
    required String conversationId,
    required String voiceUrl,
  });

  Future<void> sendFileMessage({
    required String conversationId,
    required String fileName,
    required String fileUrl,
  });

  Future<void> blockConnection(String profileId);

  Future<void> removeConnection(String profileId);

  Future<void> deleteConversation(String conversationId);
}

final class SupabaseMessageRepository implements MessageRepository {
  SupabaseMessageRepository({required this.client});

  static const _conversationPageSize = 30;
  static const _messagePageSize = 50;

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
      final conversations = await _fetchConversationRows(remote, profileId);
      final withUnread = await _withUnreadCounts(
        remote,
        profileId,
        _dedupeConversations(conversations),
      );
      return _withConnectionConversations(
        remote,
        profileId,
        _dedupeConversations(withUnread),
      );
    } catch (_) {
      try {
        final profileId = await _currentProfileId(remote);
        if (profileId == null) {
          return const [];
        }
        final rows = await remote.rpc<List<dynamic>>(
          'get_user_conversations',
          params: {'p_profile_id': profileId},
        );
        final conversations = [
          for (var i = 0; i < rows.length; i++)
            _conversationFromRpc(
              Map<String, dynamic>.from(rows[i] as Map),
              colorIndex: i,
            ),
        ];
        final hydrated = await _hydrateConversationProfilesById(
          remote,
          _dedupeConversations(conversations),
        );
        final withUnread = await _withUnreadCounts(remote, profileId, hydrated);
        return _withConnectionConversations(
          remote,
          profileId,
          _dedupeConversations(withUnread),
        );
      } catch (_) {
        return const [];
      }
    }
  }

  Future<List<MessageItem>> _fetchConversationRows(
    SupabaseClient remote,
    String profileId,
  ) async {
    final rows = await remote
        .from('conversations')
        .select()
        .or('participant_one.eq.$profileId,participant_two.eq.$profileId')
        .order('last_message_at', ascending: false)
        .limit(_conversationPageSize);
    final conversations = [
      for (var i = 0; i < rows.length; i++)
        _conversationFromTable(
          Map<String, dynamic>.from(rows[i] as Map),
          currentProfileId: profileId,
          colorIndex: i,
        ),
    ];
    return _hydrateConversationProfilesById(remote, conversations);
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
      final actualConversationId = await _actualConversationId(
        remote,
        conversationId,
        profileId,
      );
      if (actualConversationId == null) {
        return const [];
      }
      final rows = await remote
          .from('messages')
          .select('id,sender_id,content,message_type,created_at')
          .eq('conversation_id', actualConversationId)
          .order('created_at', ascending: false)
          .limit(_messagePageSize);
      _conversationCache.clear();
      unawaited(_markConversationRead(remote, actualConversationId, profileId));
      return [
        for (final row in rows.reversed)
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
    final trimmed = content.trim();
    if (conversationId.isEmpty || trimmed.isEmpty) {
      return;
    }
    await _sendTypedMessage(
      conversationId: conversationId,
      content: trimmed,
      messageType: 'text',
      failureMessage: 'تعذر إرسال الرسالة الآن',
    );
  }

  @override
  Future<void> sendVoiceMessage({
    required String conversationId,
    required String voiceUrl,
  }) async {
    if (conversationId.isEmpty || voiceUrl.trim().isEmpty) {
      return;
    }
    await _sendTypedMessage(
      conversationId: conversationId,
      content: voiceUrl.trim(),
      messageType: 'voice',
      failureMessage: 'تعذر إرسال الرسالة الصوتية الآن',
    );
  }

  @override
  Future<void> sendFileMessage({
    required String conversationId,
    required String fileName,
    required String fileUrl,
  }) async {
    final name = fileName.trim().isEmpty ? 'ملف' : fileName.trim();
    final url = fileUrl.trim();
    if (conversationId.isEmpty || url.isEmpty) {
      return;
    }
    final messageType = _messageTypeForAttachment(name, url);
    await _sendTypedMessage(
      conversationId: conversationId,
      content: '$name\n$url',
      messageType: messageType,
      failureMessage: 'تعذر إرسال الملف الآن',
    );
  }

  String _messageTypeForAttachment(String fileName, String url) {
    final lower = '$fileName $url'.toLowerCase();
    if (lower.startsWith('data:image/') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif')) {
      return 'image';
    }
    if (lower.startsWith('data:video/') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.m4v')) {
      return 'video';
    }
    return 'file';
  }

  Future<void> _sendTypedMessage({
    required String conversationId,
    required String content,
    required String messageType,
    required String failureMessage,
  }) async {
    final remote = client;
    if (remote == null) {
      return;
    }
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        throw const RepositoryFailure('سجل الدخول أولا لإرسال الرسائل');
      }
      final actualConversationId = await _actualConversationId(
        remote,
        conversationId,
        profileId,
      );
      if (actualConversationId == null) {
        throw RepositoryFailure(failureMessage);
      }
      await remote.from('messages').insert({
        'conversation_id': actualConversationId,
        'sender_id': profileId,
        'content': content,
        'message_type': messageType,
      });
      await _notifyConversationRecipient(
        remote,
        conversationId: actualConversationId,
        senderProfileId: profileId,
        messageType: messageType,
        content: content,
      );
      _messageCaches[conversationId]?.clear();
      _messageCaches[actualConversationId]?.clear();
      _conversationCache.clear();
    } on RepositoryFailure {
      rethrow;
    } catch (error) {
      throw RepositoryFailure(failureMessage, error);
    }
  }

  @override
  Future<void> blockConnection(String profileId) async {
    final remote = client;
    if (remote == null || profileId.isEmpty) {
      return;
    }
    try {
      final currentProfileId = await _currentProfileId(remote);
      if (currentProfileId == null || currentProfileId == profileId) {
        return;
      }
      try {
        await remote.from('blocked_profiles').upsert({
          'blocker_profile_id': currentProfileId,
          'blocked_profile_id': profileId,
        }, onConflict: 'blocker_profile_id,blocked_profile_id');
      } catch (_) {
        // Older databases without the block table still remove the connection.
      }
      await removeConnection(profileId);
      _conversationCache.clear();
    } catch (error) {
      throw RepositoryFailure('تعذر حظر هذا الاتصال الآن', error);
    }
  }

  @override
  Future<void> removeConnection(String profileId) async {
    final remote = client;
    if (remote == null || profileId.isEmpty) {
      return;
    }
    try {
      final currentProfileId = await _currentProfileId(remote);
      if (currentProfileId == null || currentProfileId == profileId) {
        return;
      }
      await remote
          .from('connection_requests')
          .update({
            'status': 'cancelled',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .or(
            'and(requester_profile_id.eq.$currentProfileId,receiver_profile_id.eq.$profileId),and(requester_profile_id.eq.$profileId,receiver_profile_id.eq.$currentProfileId)',
          );
      _conversationCache.clear();
    } catch (error) {
      throw RepositoryFailure('تعذر إزالة هذا الاتصال الآن', error);
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    final remote = client;
    if (remote == null || conversationId.isEmpty) {
      return;
    }
    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return;
      }
      final actualConversationId = await _actualConversationId(
        remote,
        conversationId,
        profileId,
      );
      if (actualConversationId == null) {
        return;
      }
      await remote
          .from('messages')
          .delete()
          .eq('conversation_id', actualConversationId);
      await remote
          .from('conversations')
          .delete()
          .eq('id', actualConversationId);
      _messageCaches[conversationId]?.clear();
      _messageCaches[actualConversationId]?.clear();
      _conversationCache.clear();
    } catch (error) {
      throw RepositoryFailure('تعذر حذف المحادثة الآن', error);
    }
  }

  MessageItem _conversationFromRpc(
    Map<String, dynamic> row, {
    required int colorIndex,
  }) {
    final name =
        '${row['recipient_name'] ?? row['other_name'] ?? row['full_name'] ?? row['name'] ?? 'محادثة'}';
    final unreadCount = _intFrom(row['unread_count']);
    final profileId =
        row['recipient_profile_id'] ??
        row['other_profile_id'] ??
        row['profile_id'] ??
        row['participant_profile_id'];
    final avatarUrl =
        row['recipient_avatar_url'] ??
        row['other_avatar_url'] ??
        row['avatar_url'];
    return MessageItem(
      conversationId: '${row['conversation_id'] ?? row['id'] ?? ''}',
      profileId: profileId == null ? null : '$profileId',
      name: name,
      preview: '${row['last_message'] ?? ''}',
      time: _timeLabel(row['last_message_at'] ?? row['updated_at']),
      unread: unreadCount > 0,
      unreadCount: unreadCount,
      color: _colorForIndex(colorIndex),
      avatarUrl: avatarUrl == null ? null : '$avatarUrl',
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
      type: '${row['message_type'] ?? 'text'}',
    );
  }

  Future<void> _markConversationRead(
    SupabaseClient remote,
    String conversationId,
    String profileId,
  ) async {
    try {
      await remote
          .from('messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .neq('sender_id', profileId)
          .filter('read_at', 'is', null);
      await remote
          .from('messages')
          .update({'is_read': true})
          .eq('conversation_id', conversationId)
          .neq('sender_id', profileId)
          .eq('is_read', false);
      _conversationCache.clear();
    } catch (_) {
      // Older databases without read tracking still show messages normally.
    }
  }

  Future<List<MessageItem>> _withUnreadCounts(
    SupabaseClient remote,
    String profileId,
    List<MessageItem> conversations,
  ) async {
    final ids = [
      for (final item in conversations)
        if (!item.conversationId.startsWith('connection:')) item.conversationId,
    ];
    if (ids.isEmpty) {
      return conversations;
    }
    try {
      final rows = await remote
          .from('messages')
          .select('conversation_id')
          .inFilter('conversation_id', ids)
          .neq('sender_id', profileId)
          .filter('read_at', 'is', null);
      final counts = <String, int>{};
      for (final raw in rows) {
        final id = '${(raw as Map)['conversation_id'] ?? ''}';
        if (id.isNotEmpty) {
          counts[id] = (counts[id] ?? 0) + 1;
        }
      }
      return [
        for (final item in conversations)
          _conversationWithUnread(item, counts[item.conversationId] ?? 0),
      ];
    } catch (_) {
      return conversations;
    }
  }

  MessageItem _conversationWithUnread(MessageItem item, int unreadCount) {
    return MessageItem(
      conversationId: item.conversationId,
      profileId: item.profileId,
      name: item.name,
      preview: item.preview,
      time: item.time,
      unread: unreadCount > 0,
      unreadCount: unreadCount,
      color: item.color,
      avatarUrl: item.avatarUrl,
    );
  }

  List<MessageItem> _dedupeConversations(List<MessageItem> conversations) {
    final byProfile = <String, MessageItem>{};
    final withoutProfile = <MessageItem>[];
    for (final item in conversations) {
      final key = item.profileId;
      if (key == null || key.isEmpty) {
        withoutProfile.add(item);
        continue;
      }
      final existing = byProfile[key];
      if (existing == null ||
          (!existing.unread && item.unread) ||
          (existing.preview.isEmpty && item.preview.isNotEmpty)) {
        byProfile[key] = item;
      }
    }
    return [...byProfile.values, ...withoutProfile];
  }

  Future<List<MessageItem>> _withConnectionConversations(
    SupabaseClient remote,
    String profileId,
    List<MessageItem> conversations,
  ) async {
    try {
      final blockedIds = <String>{};
      try {
        final blockedRows = await remote
            .from('blocked_profiles')
            .select('blocked_profile_id')
            .eq('blocker_profile_id', profileId);
        blockedIds.addAll({
          for (final raw in blockedRows)
            '${(raw as Map)['blocked_profile_id'] ?? ''}',
        });
      } catch (_) {
        // Blocking is optional on older databases.
      }
      final knownProfileIds = {
        for (final item in conversations)
          if (item.profileId != null) item.profileId!,
      };
      final rows = await remote
          .from('connection_requests')
          .select('requester_profile_id,receiver_profile_id,status')
          .eq('status', 'accepted')
          .or(
            'requester_profile_id.eq.$profileId,receiver_profile_id.eq.$profileId',
          );
      final connectionIds =
          <String>{
            for (final raw in rows)
              () {
                final row = Map<String, dynamic>.from(raw as Map);
                final requester = '${row['requester_profile_id'] ?? ''}';
                final receiver = '${row['receiver_profile_id'] ?? ''}';
                return requester == profileId ? receiver : requester;
              }(),
          }..removeWhere(
            (id) =>
                id.isEmpty ||
                knownProfileIds.contains(id) ||
                blockedIds.contains(id),
          );
      if (connectionIds.isEmpty) {
        return conversations;
      }
      final profiles = await remote
          .from('profiles')
          .select('id,full_name,role,bio,avatar_url')
          .inFilter('id', connectionIds.toList());
      return [
        ...conversations,
        for (var i = 0; i < profiles.length; i++)
          _connectionConversationFromProfile(
            Map<String, dynamic>.from(profiles[i] as Map),
            colorIndex: conversations.length + i,
          ),
      ];
    } catch (_) {
      return conversations;
    }
  }

  MessageItem _connectionConversationFromProfile(
    Map<String, dynamic> row, {
    required int colorIndex,
  }) {
    final name = '${row['full_name'] ?? 'مستخدم'}'.trim();
    final profileId = '${row['id'] ?? ''}';
    return MessageItem(
      conversationId: 'connection:$profileId',
      profileId: profileId,
      name: name.isEmpty ? 'مستخدم' : name,
      preview: '${row['bio'] ?? row['role'] ?? 'اتصال جديد'}',
      time: '',
      unread: false,
      unreadCount: 0,
      color: _colorForIndex(colorIndex),
      avatarUrl: row['avatar_url'] == null ? null : '${row['avatar_url']}',
    );
  }

  Future<List<MessageItem>> _hydrateConversationProfilesById(
    SupabaseClient remote,
    List<MessageItem> conversations,
  ) async {
    final ids = {
      for (final item in conversations)
        if (item.profileId != null && item.profileId!.isNotEmpty)
          item.profileId!,
    };
    if (ids.isEmpty) {
      return conversations;
    }
    try {
      final profiles = await remote
          .from('profiles')
          .select('id,full_name,role,bio,avatar_url')
          .inFilter('id', ids.toList());
      final byId = <String, Map<String, dynamic>>{
        for (final raw in profiles)
          '${(raw as Map)['id'] ?? ''}': Map<String, dynamic>.from(raw),
      };
      return [
        for (final item in conversations)
          _conversationWithProfile(item, byId[item.profileId]),
      ];
    } catch (_) {
      return conversations;
    }
  }

  MessageItem _conversationWithProfile(
    MessageItem item,
    Map<String, dynamic>? profile,
  ) {
    if (profile == null) {
      return item;
    }
    final name = '${profile['full_name'] ?? ''}'.trim();
    return MessageItem(
      conversationId: item.conversationId,
      profileId: item.profileId,
      name: name.isEmpty ? item.name : name,
      preview: item.preview.isNotEmpty
          ? item.preview
          : '${profile['bio'] ?? profile['role'] ?? ''}',
      time: item.time,
      unread: item.unread,
      unreadCount: item.unreadCount,
      color: item.color,
      avatarUrl: profile['avatar_url'] == null
          ? item.avatarUrl
          : '${profile['avatar_url']}',
    );
  }

  Future<String?> _actualConversationId(
    SupabaseClient remote,
    String conversationId,
    String profileId,
  ) async {
    if (!conversationId.startsWith('connection:')) {
      return conversationId;
    }
    final otherProfileId = conversationId.substring('connection:'.length);
    if (otherProfileId.isEmpty || otherProfileId == profileId) {
      return null;
    }
    try {
      final existingRows = await remote
          .from('conversations')
          .select('id')
          .or(
            'and(participant_one.eq.$profileId,participant_two.eq.$otherProfileId),and(participant_one.eq.$otherProfileId,participant_two.eq.$profileId)',
          )
          .order('last_message_at', ascending: false)
          .limit(1);
      if (existingRows.isNotEmpty) {
        return '${(existingRows.first as Map)['id']}';
      }
      final ordered = _orderedParticipants(profileId, otherProfileId);
      final row = await remote
          .from('conversations')
          .insert({
            'participant_one': ordered.$1,
            'participant_two': ordered.$2,
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      return '${row['id']}';
    } catch (_) {
      return null;
    }
  }

  (String, String) _orderedParticipants(String a, String b) {
    return a.compareTo(b) <= 0 ? (a, b) : (b, a);
  }

  Future<void> _notifyConversationRecipient(
    SupabaseClient remote, {
    required String conversationId,
    required String senderProfileId,
    required String messageType,
    required String content,
  }) async {
    try {
      final conversation = await remote
          .from('conversations')
          .select('participant_one,participant_two')
          .eq('id', conversationId)
          .maybeSingle();
      if (conversation == null) {
        return;
      }
      final one = '${conversation['participant_one'] ?? ''}';
      final two = '${conversation['participant_two'] ?? ''}';
      final recipient = one == senderProfileId ? two : one;
      if (recipient.isEmpty || recipient == senderProfileId) {
        return;
      }
      await remote.from('notifications').insert({
        'profile_id': recipient,
        'title': 'رسالة جديدة',
        'message': switch (messageType) {
          'voice' => 'وصلتك رسالة صوتية جديدة',
          'image' => 'وصلتك صورة جديدة',
          'video' => 'وصلك فيديو جديد',
          'file' => 'وصلك ملف جديد',
          _ => content.split('\n').first,
        },
        'type': 'message',
        'action_url': 'app://chat/$conversationId',
      });
    } catch (_) {
      // Notifications are best-effort and should not block sending.
    }
  }

  String _timeLabel(Object? value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) {
      return '';
    }
    String two(int number) => number.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
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
