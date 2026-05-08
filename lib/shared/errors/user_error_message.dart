import '../../data/repositories/repository_failure.dart';

String userErrorMessage(
  Object error, {
  String fallback = 'تعذر تنفيذ العملية الآن',
}) {
  if (error is RepositoryFailure) {
    return error.message;
  }
  if (error is String && _looksUserSafe(error)) {
    return error;
  }
  return fallback;
}

bool _looksUserSafe(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty || trimmed.length > 160) {
    return false;
  }
  final lower = trimmed.toLowerCase();
  const sensitiveFragments = [
    'supabase',
    'postgrest',
    'postgres',
    'sqlstate',
    'row-level',
    'row level',
    'rls',
    'jwt',
    'schema',
    'relation',
    'violates',
    'exception',
    'stack',
    'policy',
    'permission denied',
  ];
  if (sensitiveFragments.any(lower.contains)) {
    return false;
  }
  return RegExp(r'[\u0600-\u06FF]').hasMatch(trimmed);
}
