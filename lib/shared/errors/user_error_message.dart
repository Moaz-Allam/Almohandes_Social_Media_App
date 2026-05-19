import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/repository_failure.dart';

/// Turns any thrown object into an Arabic message safe to show to a user.
///
/// Strategy:
/// 1. [RepositoryFailure.message] — already curated by the repo layer.
/// 2. [AuthException] — invalid credentials, email taken, OTP errors, …
/// 3. [PostgrestException] — RLS denied, FK violation, unique violation, …
/// 4. [StorageException] — file too large, MIME not allowed, RLS, …
/// 5. [FunctionException] — pull `message` out of details/data if present.
/// 6. Network: [SocketException], [HttpException], [TimeoutException].
/// 7. Plain [String] (only if it's clearly already user-safe Arabic text).
/// 8. [fallback].
///
/// Never returns raw stack/SQL/JSON to the user.
String userErrorMessage(
  Object error, {
  String fallback = 'تعذر تنفيذ العملية الآن. حاول مرة أخرى بعد لحظات',
}) {
  if (error is RepositoryFailure) {
    return error.message;
  }
  if (error is AuthException) {
    return _authMessage(error);
  }
  if (error is PostgrestException) {
    return _postgrestMessage(error, fallback: fallback);
  }
  if (error is StorageException) {
    return _storageMessage(error);
  }
  if (error is FunctionException) {
    return _functionMessage(error, fallback: fallback);
  }
  if (error is SocketException) {
    return 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى';
  }
  if (error is HttpException) {
    return 'فشل الاتصال بالخادم. حاول مرة أخرى';
  }
  if (error is TimeoutException) {
    return 'استغرق الاتصال وقتا أطول من المعتاد. حاول مرة أخرى';
  }
  if (error is FormatException) {
    return 'القيمة المدخلة غير صحيحة. تحقق منها ثم أعد المحاولة';
  }
  if (error is String && _looksUserSafe(error)) {
    return error;
  }
  return fallback;
}

String _authMessage(AuthException error) {
  final raw = error.message.toLowerCase();
  final code = (error.code ?? '').toLowerCase();

  bool has(String token) => raw.contains(token) || code.contains(token);

  if (has('invalid login') ||
      has('invalid_credentials') ||
      has('invalid email or password') ||
      has('email not confirmed') == false &&
          has('invalid grant')) {
    return 'بيانات الدخول غير صحيحة. تحقق من البريد/الهاتف وكلمة المرور';
  }
  if (has('email not confirmed') || has('email_not_confirmed')) {
    return 'لم يتم تأكيد البريد بعد. افتح الرسالة من بريدك واضغط رابط التأكيد';
  }
  if (has('user already registered') ||
      has('email_exists') ||
      has('already registered') ||
      has('duplicate key value') && has('email')) {
    return 'هذا البريد مستخدم بالفعل. سجل الدخول أو استخدم بريدا آخر';
  }
  if (has('phone_exists') || (has('duplicate key value') && has('phone'))) {
    return 'هذا الرقم مستخدم بالفعل. سجل الدخول أو استخدم رقما آخر';
  }
  if (has('weak_password') ||
      has('password should be at least') ||
      has('password is too weak')) {
    return 'كلمة المرور ضعيفة جدا. استخدم 6 أحرف على الأقل تجمع بين أحرف وأرقام';
  }
  if (has('rate limit') || has('too many requests') || has('over_request_rate_limit')) {
    return 'تم إجراء محاولات كثيرة. انتظر دقيقة ثم حاول مرة أخرى';
  }
  if (has('user not found') ||
      has('email_not_found') ||
      has('phone_not_found')) {
    return 'لا يوجد حساب مسجل بهذه البيانات. سجل اشتراكا جديدا أولا';
  }
  if (has('signup is disabled') || has('signup_disabled')) {
    return 'التسجيل غير متاح حاليا. حاول مرة أخرى لاحقا';
  }
  if (has('jwt') || has('session') || has('token expired')) {
    return 'انتهت صلاحية جلسة الدخول. سجل الدخول مرة أخرى';
  }
  if (has('captcha')) {
    return 'تعذر التحقق من أنك لست روبوتا. حاول مرة أخرى';
  }
  if (has('otp') || has('verification code') || has('invalid token')) {
    return 'رمز التحقق غير صحيح أو منتهي الصلاحية. اطلب رمزا جديدا';
  }
  if (has('phone') && has('invalid')) {
    return 'رقم الهاتف غير صحيح. أعد إدخاله بدون رموز إضافية';
  }
  if (has('email') && has('invalid')) {
    return 'صيغة البريد الإلكتروني غير صحيحة';
  }
  if (has('failed host lookup') ||
      has('socketexception') ||
      has('network')) {
    return 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وحاول مرة أخرى';
  }
  return 'تعذر إكمال طلب الحساب. حاول مرة أخرى أو تواصل مع الدعم';
}

String _postgrestMessage(
  PostgrestException error, {
  required String fallback,
}) {
  final code = error.code ?? '';
  final raw = (error.message).toLowerCase();
  switch (code) {
    case '23505': // unique_violation
      if (raw.contains('email')) {
        return 'هذا البريد مستخدم بالفعل';
      }
      if (raw.contains('phone')) {
        return 'هذا الرقم مستخدم بالفعل';
      }
      if (raw.contains('username')) {
        return 'اسم المستخدم محجوز. اختر اسما آخر';
      }
      return 'هذه القيمة مسجلة من قبل. استخدم قيمة مختلفة';
    case '23503': // foreign_key_violation
      return 'تعذر حفظ التغييرات لوجود مرجع غير صحيح. أعد تحميل الصفحة وحاول مرة أخرى';
    case '23502': // not_null_violation
      return 'بعض الحقول الإلزامية فارغة. أكمل البيانات ثم أعد المحاولة';
    case '23514': // check_violation
      return 'إحدى القيم لا تطابق القيود المسموح بها. تحقق من البيانات';
    case '42501': // insufficient_privilege
    case 'PGRST301':
    case '42P01':
      return 'لا تملك الصلاحيات اللازمة لهذه العملية';
    case 'PGRST116':
      return 'لم يتم العثور على البيانات المطلوبة';
    case 'PGRST204':
      return 'لا توجد بيانات لعرضها';
    case '57014': // query_canceled
      return 'تأخر الرد من الخادم. حاول مرة أخرى';
  }
  if (raw.contains('row-level security') ||
      raw.contains('policy') ||
      raw.contains('permission denied')) {
    return 'لا تملك الصلاحيات اللازمة لهذه العملية';
  }
  if (raw.contains('jwt')) {
    return 'انتهت صلاحية جلسة الدخول. سجل الدخول مرة أخرى';
  }
  if (raw.contains('timeout') || raw.contains('time-out')) {
    return 'تأخر الرد من الخادم. حاول مرة أخرى';
  }
  return fallback;
}

String _storageMessage(StorageException error) {
  final raw = error.message.toLowerCase();
  if (raw.contains('exceeded') ||
      raw.contains('too large') ||
      raw.contains('payload') ||
      raw.contains('size limit')) {
    return 'حجم الملف أكبر من الحد المسموح. اختر ملفا أصغر';
  }
  if (raw.contains('mime') || raw.contains('content type')) {
    return 'نوع الملف غير مدعوم. اختر صورة أو فيديو بصيغة مدعومة';
  }
  if (raw.contains('not authorized') ||
      raw.contains('rls') ||
      raw.contains('permission')) {
    return 'لا تملك صلاحية رفع هذا الملف';
  }
  if (raw.contains('already exists') || raw.contains('duplicate')) {
    return 'يوجد ملف مرفوع بنفس الاسم. حاول مرة أخرى';
  }
  if (raw.contains('not found')) {
    return 'تعذر إيجاد الملف على الخادم';
  }
  if (raw.contains('network') || raw.contains('failed to fetch')) {
    return 'فشل الاتصال أثناء الرفع. تحقق من الشبكة وحاول مرة أخرى';
  }
  return 'تعذر رفع الملف الآن. حاول مرة أخرى';
}

String _functionMessage(
  FunctionException error, {
  required String fallback,
}) {
  final details = error.details;
  if (details is Map) {
    final message = details['message'];
    if (message is String && _looksUserSafe(message)) {
      return message;
    }
    final errorField = details['error'];
    if (errorField is String && _looksUserSafe(errorField)) {
      return errorField;
    }
  }
  final status = error.status;
  if (status == 429) {
    return 'تم إجراء طلبات كثيرة. انتظر دقيقة ثم حاول مرة أخرى';
  }
  if (status == 401 || status == 403) {
    return 'لا تملك الصلاحيات اللازمة لهذه العملية';
  }
  if (status == 408 || status == 504) {
    return 'تأخر الرد من الخادم. حاول مرة أخرى';
  }
  if (status >= 500) {
    return 'خطأ في الخادم. حاول مرة أخرى بعد قليل';
  }
  return fallback;
}

bool _looksUserSafe(String message) {
  final trimmed = message.trim();
  if (trimmed.isEmpty || trimmed.length > 200) {
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
    'duplicate key value',
    'pgrst',
    'syntaxerror',
    'fetch failed',
    'http',
  ];
  if (sensitiveFragments.any(lower.contains)) {
    return false;
  }
  // Must contain at least one Arabic character — otherwise it's likely
  // raw English from a library that wasn't translated.
  return RegExp(r'[؀-ۿ]').hasMatch(trimmed);
}
