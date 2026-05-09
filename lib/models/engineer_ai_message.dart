enum EngineerAiRole {
  user,
  assistant;

  static EngineerAiRole fromValue(Object? value) {
    return value == 'user' ? EngineerAiRole.user : EngineerAiRole.assistant;
  }
}

final class EngineerAiMessage {
  const EngineerAiMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final EngineerAiRole role;
  final String content;
  final DateTime createdAt;

  bool get isUser => role == EngineerAiRole.user;

  factory EngineerAiMessage.fromMap(Map<String, dynamic> map) {
    return EngineerAiMessage(
      id: '${map['id'] ?? ''}',
      role: EngineerAiRole.fromValue(map['role']),
      content: '${map['content'] ?? ''}',
      createdAt:
          DateTime.tryParse('${map['created_at'] ?? ''}') ?? DateTime.now(),
    );
  }
}
