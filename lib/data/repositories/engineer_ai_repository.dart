import 'package:supabase_flutter/supabase_flutter.dart';

import '../session/current_profile_resolver.dart';

import '../../models/engineer_ai_message.dart';
import 'repository_failure.dart';

abstract interface class EngineerAiRepository {
  Future<List<EngineerAiMessage>> fetchMessages({bool forceRefresh = false});

  Future<EngineerAiMessage> sendMessage(String content);
}

final class SupabaseEngineerAiRepository implements EngineerAiRepository {
  SupabaseEngineerAiRepository({required this.client});

  final SupabaseClient? client;

  @override
  Future<List<EngineerAiMessage>> fetchMessages({
    bool forceRefresh = false,
  }) async {
    final remote = client;
    if (remote == null) {
      return const [];
    }

    try {
      final profileId = await _currentProfileId(remote);
      if (profileId == null) {
        return const [];
      }
      final conversation = await remote
          .from('ai_conversations')
          .select('id')
          .eq('profile_id', profileId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (conversation == null) {
        return const [];
      }

      final rows = await remote
          .from('ai_messages')
          .select('id,role,content,created_at')
          .eq('conversation_id', '${conversation['id']}')
          .order('created_at', ascending: false)
          .limit(40);
      return [
        for (final row in rows.reversed)
          EngineerAiMessage.fromMap(Map<String, dynamic>.from(row as Map)),
      ];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<EngineerAiMessage> sendMessage(String content) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure('خدمة المهندسة إنجي غير مهيأة الآن');
    }
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const RepositoryFailure('اكتب رسالتك أولاً');
    }
    if (trimmed.length > 2000) {
      throw const RepositoryFailure('اختصر الرسالة إلى أقل من 2000 حرف');
    }

    try {
      final accessToken = await _currentAccessToken(remote);
      if (accessToken == null || accessToken.isEmpty) {
        throw const RepositoryFailure(
          'انتهت جلسة الدخول. سجل الدخول مرة أخرى.',
        );
      }
      final response = await remote.functions.invoke(
        'engee-chat',
        headers: {
          'Authorization': 'Bearer $accessToken',
          'x-customer-auth': 'Bearer $accessToken',
        },
        body: {'message': trimmed, 'content': trimmed, 'text': trimmed},
      );
      final data = response.data;
      if (data is Map && data['success'] == false) {
        throw RepositoryFailure(
          '${data['message'] ?? 'تعذر إرسال الرسالة إلى إنجي الآن'}',
        );
      }
      if (data is Map && data['assistantMessage'] is Map) {
        return EngineerAiMessage.fromMap(
          Map<String, dynamic>.from(data['assistantMessage'] as Map),
        );
      }
      if (data is Map && data['message'] is String) {
        return EngineerAiMessage(
          id: 'remote-${DateTime.now().microsecondsSinceEpoch}',
          role: EngineerAiRole.assistant,
          content: '${data['message']}',
          createdAt: DateTime.now(),
        );
      }
      throw const RepositoryFailure('تعذر قراءة رد إنجي الآن');
    } catch (error) {
      if (error is RepositoryFailure) {
        rethrow;
      }
      final message = _functionErrorMessage(error);
      if (message != null) {
        throw RepositoryFailure(message, error);
      }
      throw RepositoryFailure('تعذر إرسال الرسالة إلى إنجي الآن', error);
    }
  }

  Future<String?> _currentProfileId(SupabaseClient remote) =>
      CurrentProfileResolver.instance.resolve(client: remote);

  Future<String?> _currentAccessToken(SupabaseClient remote) async {
    final currentSession = remote.auth.currentSession;
    if (currentSession != null &&
        !currentSession.isExpired &&
        currentSession.accessToken.isNotEmpty) {
      return currentSession.accessToken;
    }
    try {
      final refreshed = await remote.auth.refreshSession();
      final refreshedToken = refreshed.session?.accessToken;
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        return refreshedToken;
      }
    } catch (_) {
      // The caller will surface a sign-in prompt if no valid token remains.
    }
    final fallbackSession = remote.auth.currentSession;
    if (fallbackSession != null &&
        !fallbackSession.isExpired &&
        fallbackSession.accessToken.isNotEmpty) {
      return fallbackSession.accessToken;
    }
    return null;
  }

  String? _functionErrorMessage(Object error) {
    if (error is! FunctionException) {
      return null;
    }
    final detailsMessage = _functionDetailsMessage(error.details);
    if (detailsMessage != null) {
      return detailsMessage;
    }
    if (error.status == 401) {
      return 'انتهت جلسة الدخول. سجل الدخول مرة أخرى.';
    }
    if (error.status == 403) {
      return 'هذه الميزة متاحة لمشتركي Premium فقط.';
    }
    return null;
  }

  String? _functionDetailsMessage(Object? details) {
    if (details is Map) {
      final message = details['message'] ?? details['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }
}
