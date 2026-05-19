import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/account_type.dart';
import '../../models/profile_form.dart';
import '../../shared/errors/user_error_message.dart';
import '../mappers/supabase_enum_mapper.dart';
import '../session/session_store.dart';
import 'repository_failure.dart';

abstract interface class AuthRepository {
  bool get isRemoteConfigured;

  Future<void> signInWithPassword({
    required String login,
    required String password,
  });

  Future<void> sendPasswordReset({required String email});

  Future<void> updatePassword({required String password});

  Future<String?> sendOtp({required String phone});

  Future<bool> verifyOtp({required String phone, required String code});

  Future<void> completeSignUp({
    required ProfileForm profile,
    required AccountType accountType,
    required String specialization,
    required String phone,
    required String password,
  });

  Future<void> signOut();
}

final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({required this.client, required this.sessionStore});

  final SupabaseClient? client;
  final SessionStore sessionStore;

  @override
  bool get isRemoteConfigured => client != null;

  @override
  Future<void> signInWithPassword({
    required String login,
    required String password,
  }) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure(
        'خدمة تسجيل الدخول غير متاحة الآن. تحقق من اتصالك بالإنترنت ثم حاول مرة أخرى',
      );
    }
    final trimmedLogin = login.trim();
    if (trimmedLogin.isEmpty) {
      throw const RepositoryFailure('أدخل بريدك الإلكتروني أو رقم هاتفك');
    }
    if (password.isEmpty) {
      throw const RepositoryFailure('أدخل كلمة المرور');
    }

    AuthException? lastAuthError;
    try {
      if (trimmedLogin.contains('@')) {
        await remote.auth.signInWithPassword(
          email: trimmedLogin,
          password: password,
        );
      } else {
        final normalizedPhone = _normalizePhone(trimmedLogin);
        try {
          await remote.auth.signInWithPassword(
            phone: normalizedPhone,
            password: password,
          );
        } on AuthException catch (err) {
          // Some older accounts were registered with the synthetic
          // "phone-as-email" address. Fall back to that before giving up,
          // but remember the real error in case the fallback also fails.
          lastAuthError = err;
          await remote.auth.signInWithPassword(
            email: _phoneOnlyAuthEmail(normalizedPhone),
            password: password,
          );
        }
      }
      await sessionStore.saveSignedIn();
    } on AuthException catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          lastAuthError ?? error,
          fallback: 'بيانات الدخول غير صحيحة. تحقق منها ثم حاول مرة أخرى',
        ),
        error,
      );
    } catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback: 'تعذر تسجيل الدخول. تحقق من الاتصال وحاول مرة أخرى',
        ),
        error,
      );
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure(
        'خدمة استعادة كلمة المرور غير متاحة الآن. تحقق من الاتصال وحاول مرة أخرى',
      );
    }
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw const RepositoryFailure(
        'أدخل بريدك الإلكتروني لاستعادة كلمة المرور',
      );
    }
    if (!_isValidEmail(trimmed)) {
      throw const RepositoryFailure(
        'صيغة البريد الإلكتروني غير صحيحة. استخدم صيغة مثل name@example.com',
      );
    }

    try {
      await remote.auth.resetPasswordForEmail(
        trimmed,
        redirectTo: 'com.almohandes.app://reset-password',
      );
    } catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'تعذر إرسال رابط استعادة كلمة المرور. تحقق من البريد الإلكتروني وحاول مرة أخرى',
        ),
        error,
      );
    }
  }

  @override
  Future<void> updatePassword({required String password}) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure(
        'خدمة تغيير كلمة المرور غير متاحة الآن. تحقق من الاتصال وحاول مرة أخرى',
      );
    }
    final value = password.trim();
    if (value.isEmpty) {
      throw const RepositoryFailure('أدخل كلمة المرور الجديدة');
    }
    if (value.length < 6) {
      throw const RepositoryFailure(
        'كلمة المرور قصيرة جدا. استخدم 6 أحرف على الأقل',
      );
    }

    try {
      await remote.auth.updateUser(UserAttributes(password: value));
    } catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'تعذر تغيير كلمة المرور. تأكد من فتح رابط الاستعادة في نفس الجهاز ثم حاول مرة أخرى',
        ),
        error,
      );
    }
  }

  @override
  Future<String?> sendOtp({required String phone}) async {
    final remote = client;
    if (remote == null) {
      return null;
    }

    final normalized = _normalizePhone(phone);
    if (!_looksLikePhone(normalized)) {
      throw const RepositoryFailure(
        'رقم الهاتف غير صحيح. أدخل رقما عراقيا (07xxxxxxxxx) أو مصريا (01xxxxxxxxx)',
      );
    }
    try {
      final response = await remote.functions.invoke(
        'send-otp',
        body: {'phone': normalized},
      );
      final data = response.data;
      if (data is Map && data['sent'] == false) {
        throw RepositoryFailure(
          '${data['message'] ?? 'تعذر إرسال رمز التحقق. تحقق من رقم الهاتف وحاول مرة أخرى'}',
        );
      }
      if (data is Map) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
      return null;
    } catch (error) {
      if (error is RepositoryFailure) {
        rethrow;
      }
      final message = _functionErrorMessage(error);
      if (message != null) {
        throw RepositoryFailure(message, error);
      }
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'تعذر إرسال رمز التحقق الآن. تحقق من الشبكة وحاول مرة أخرى',
        ),
        error,
      );
    }
  }

  @override
  Future<bool> verifyOtp({required String phone, required String code}) async {
    final remote = client;
    if (remote == null) {
      return code.trim() == '123456';
    }
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      throw const RepositoryFailure('أدخل رمز التحقق المرسل إلى هاتفك');
    }
    if (!RegExp(r'^\d{4,8}$').hasMatch(trimmedCode)) {
      throw const RepositoryFailure(
        'رمز التحقق يجب أن يتكون من أرقام فقط',
      );
    }

    try {
      final edgeResponse = await remote.functions.invoke(
        'verify-otp',
        body: {'phone': _normalizePhone(phone), 'code': trimmedCode},
      );
      final edgeData = edgeResponse.data;
      if (edgeData is Map) {
        if (edgeData['verified'] == true) {
          return true;
        }
        if (edgeData['message'] != null) {
          throw RepositoryFailure('${edgeData['message']}');
        }
        return false;
      }
    } catch (error) {
      if (error is RepositoryFailure) {
        rethrow;
      }
      final message = _functionErrorMessage(error);
      if (message != null) {
        throw RepositoryFailure(message, error);
      }
      // Fall back to the database OTP verifier for self-hosted/dev setups.
    }

    try {
      final response = await remote.rpc<bool>(
        'verify_otp_token',
        params: {
          'p_phone_local10': _phoneLocal10(phone),
          'p_verification_code': trimmedCode,
        },
      );
      if (response != true) {
        throw const RepositoryFailure(
          'رمز التحقق غير صحيح أو منتهي الصلاحية. اطلب رمزا جديدا',
        );
      }
      return true;
    } on RepositoryFailure {
      rethrow;
    } catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'تعذر التحقق من رمز الهاتف. تحقق من الاتصال أو اطلب رمزا جديدا',
        ),
        error,
      );
    }
  }

  @override
  Future<void> completeSignUp({
    required ProfileForm profile,
    required AccountType accountType,
    required String specialization,
    required String phone,
    required String password,
  }) async {
    final remote = client;
    if (remote == null) {
      await sessionStore.saveSignedIn();
      return;
    }

    final role = accountTypeToSupabaseRole(accountType);
    final governorate = governorateToSupabase(profile.location);
    final normalizedPhone = _normalizePhone(phone);
    final profileEmail = profile.email.trim();
    if (profile.fullName.trim().isEmpty) {
      throw const RepositoryFailure('أدخل اسمك الكامل');
    }
    if (profileEmail.isEmpty) {
      throw const RepositoryFailure(
        'أدخل بريدك الإلكتروني. سنستخدمه لتسجيل الدخول واستعادة كلمة المرور',
      );
    }
    if (!_isValidEmail(profileEmail)) {
      throw const RepositoryFailure(
        'صيغة البريد الإلكتروني غير صحيحة. مثال: name@example.com',
      );
    }
    if (password.length < 6) {
      throw const RepositoryFailure(
        'كلمة المرور قصيرة جدا. استخدم 6 أحرف على الأقل',
      );
    }
    if (!_looksLikePhone(normalizedPhone)) {
      throw const RepositoryFailure(
        'رقم الهاتف غير صحيح. تحقق من الرقم ثم أعد المحاولة',
      );
    }
    final authEmail = profileEmail;
    try {
      final phoneVerified = await remote.rpc<bool>(
        'has_verified_signup_phone',
        params: {'p_phone': normalizedPhone},
      );
      if (phoneVerified != true) {
        throw const RepositoryFailure(
          'يجب تأكيد رقم الهاتف قبل إنشاء الحساب. عد للخطوة السابقة وأكمل التحقق',
        );
      }
      final authResponse = await remote.auth.signUp(
        email: authEmail,
        password: password,
        data: {
          'full_name': profile.fullName,
          'phone': normalizedPhone,
          'email': profileEmail,
          'role': role,
          'governorate': governorate,
          'bio': profile.about,
        },
      );
      if (remote.auth.currentSession == null && password.isNotEmpty) {
        try {
          await remote.auth.signInWithPassword(
            email: authEmail,
            password: password,
          );
        } catch (_) {
          // Some projects require confirmation before a Supabase session.
        }
      }
      if (remote.auth.currentSession == null) {
        throw const RepositoryFailure(
          'تم إنشاء الحساب. افتح رسالة تأكيد البريد من بريدك ثم سجل الدخول',
        );
      }
      final userId = authResponse.user?.id ?? remote.auth.currentUser?.id;
      if (userId == null) {
        throw const RepositoryFailure(
          'تعذر تأكيد جلسة الحساب الجديدة. جرّب تسجيل الدخول مباشرة',
        );
      }
      await _syncAuthPhone(remote, normalizedPhone);

      final profileId = await _upsertProfile(
        remote,
        userId: userId,
        profile: profile,
        accountType: accountType,
        phone: phone,
      );
      try {
        await _upsertDetails(
          remote,
          profileId: profileId,
          accountType: accountType,
          specialization: specialization,
          companyName: profile.company,
        );
      } catch (_) {
        // The app can continue when optional role detail tables are absent.
      }
      await sessionStore.saveSignedIn();
    } catch (error) {
      if (error is RepositoryFailure) {
        rethrow;
      }
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'تعذر إنشاء الحساب. تحقق من البيانات أو من الاتصال بالإنترنت وحاول مرة أخرى',
        ),
        error,
      );
    }
  }

  @override
  Future<void> signOut() async {
    final remote = client;
    if (remote != null) {
      try {
        await remote.auth.signOut();
      } catch (_) {
        // Local session is still cleared by AppController.
      }
    }
  }

  Future<void> _syncAuthPhone(
    SupabaseClient remote,
    String normalizedPhone,
  ) async {
    try {
      final response = await remote.functions.invoke(
        'sync-auth-phone',
        body: {'phone': normalizedPhone},
      );
      final data = response.data;
      if (data is Map && data['success'] == false) {
        throw RepositoryFailure(
          '${data['message'] ?? 'تعذر ربط رقم الهاتف بالحساب. قد يكون الرقم مستخدما من قبل'}',
        );
      }
    } catch (error) {
      if (error is RepositoryFailure) {
        rethrow;
      }
      final message = _functionErrorMessage(error);
      if (message != null) {
        throw RepositoryFailure(message, error);
      }
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'تعذر ربط رقم الهاتف بالحساب. تحقق من الرقم أو من الاتصال وحاول مرة أخرى',
        ),
        error,
      );
    }
  }

  Future<String> _upsertProfile(
    SupabaseClient remote, {
    required String userId,
    required ProfileForm profile,
    required AccountType accountType,
    required String phone,
  }) async {
    final role = accountTypeToSupabaseRole(accountType);
    final governorate = governorateToSupabase(profile.location);
    final normalizedPhone = _normalizePhone(phone);

    try {
      final profileId = await remote.rpc<String>(
        'complete_signup_profile_for_app',
        params: {
          'p_full_name': profile.fullName,
          'p_email': profile.email.trim(),
          'p_phone': normalizedPhone,
          'p_role': role,
          'p_governorate': governorate,
          'p_bio': profile.about,
        },
      );
      if (profileId.trim().isNotEmpty) {
        await _updateProfileSkills(remote, profileId.trim(), profile.skills);
        return profileId;
      }
    } catch (_) {
      // Fall back for environments where the signup RPC is not installed yet.
    }

    late final Map<String, dynamic> profileRow;
    try {
      profileRow = await _writeProfileWithTables(
        remote,
        userId: userId,
        profile: profile,
        role: role,
        governorate: governorate,
        normalizedPhone: normalizedPhone,
        includeRole: true,
      );
    } catch (_) {
      profileRow = await _writeProfileWithTables(
        remote,
        userId: userId,
        profile: profile,
        role: role,
        governorate: governorate,
        normalizedPhone: normalizedPhone,
        includeRole: false,
      );
    }

    final profileId = '${profileRow['id']}';
    await _updateProfileSkills(remote, profileId, profile.skills);
    return profileId;
  }

  Future<void> _updateProfileSkills(
    SupabaseClient remote,
    String profileId,
    Set<String> skills,
  ) async {
    final values = [
      for (final skill in skills)
        if (skill.trim().isNotEmpty) skill.trim(),
    ];
    if (profileId.isEmpty || values.isEmpty) {
      return;
    }
    try {
      await remote
          .from('profiles')
          .update({'skills': values})
          .eq('id', profileId);
    } catch (_) {
      // Older schemas may not have a skills column yet.
    }
  }

  Future<Map<String, dynamic>> _writeProfileWithTables(
    SupabaseClient remote, {
    required String userId,
    required ProfileForm profile,
    required String role,
    required String governorate,
    required String normalizedPhone,
    required bool includeRole,
  }) async {
    final existing = await remote
        .from('profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    final values = {
      'full_name': profile.fullName,
      'email': profile.email.trim().isEmpty ? null : profile.email.trim(),
      'phone': normalizedPhone,
      if (includeRole) 'role': role,
      'governorate': governorate,
      'bio': profile.about,
    };
    if (existing != null) {
      return await remote
          .from('profiles')
          .update(values)
          .eq('id', existing['id'])
          .select('id')
          .single();
    }
    return await remote
        .from('profiles')
        .insert({'user_id': userId, ...values})
        .select('id')
        .single();
  }

  Future<void> _upsertDetails(
    SupabaseClient remote, {
    required String profileId,
    required AccountType accountType,
    required String specialization,
    required String companyName,
  }) async {
    switch (accountType) {
      case AccountType.engineer:
        await remote.from('engineer_details').upsert({
          'profile_id': profileId,
          'specialization': engineerSpecializationToSupabase(specialization),
          if (companyName.isNotEmpty) 'company_name': companyName,
        }, onConflict: 'profile_id');
      case AccountType.company:
        await remote.from('contractor_details').upsert({
          'profile_id': profileId,
          'company_name': companyName,
          'status': 'available',
        }, onConflict: 'profile_id');
      case AccountType.craftsman:
        await remote.from('craftsman_details').upsert({
          'profile_id': profileId,
          'specialization': craftsmanSpecializationToSupabase(specialization),
        }, onConflict: 'profile_id');
      case AccountType.worker:
        break;
      case AccountType.equipment:
        await remote.from('machinery_details').upsert({
          'profile_id': profileId,
          'specialization': machinerySpecializationToSupabase(specialization),
          'machinery_name': specialization,
          'is_available': true,
        }, onConflict: 'profile_id');
      case AccountType.admin:
        break;
    }
  }

  String _normalizePhone(String phone) {
    final compact = phone.trim().replaceAll(' ', '').replaceAll('-', '');
    if (compact.startsWith('+964')) {
      return compact;
    }
    if (compact.startsWith('00964')) {
      return '+964${compact.substring(5)}';
    }
    if (RegExp(r'^07[3-9]\d{8}$').hasMatch(compact)) {
      return '+964${compact.substring(1)}';
    }
    if (compact.startsWith('+20')) {
      return compact;
    }
    if (compact.startsWith('0020')) {
      return '+20${compact.substring(4)}';
    }
    if (RegExp(r'^01[0125]\d{8}$').hasMatch(compact)) {
      return '+20${compact.substring(1)}';
    }
    return compact;
  }

  String _phoneOnlyAuthEmail(String normalizedPhone) {
    final digits = normalizedPhone.replaceAll(RegExp(r'\D'), '');
    return 'phone-$digits@phone.engineer.local';
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
  }

  bool _looksLikePhone(String normalized) {
    // After _normalizePhone, valid numbers start with +964 / +20 etc.
    // and are 10–15 digits total.
    return RegExp(r'^\+\d{9,14}$').hasMatch(normalized);
  }

  String? _functionErrorMessage(Object error) {
    if (error is! FunctionException) {
      return null;
    }
    final details = error.details;
    if (details is Map) {
      final message = details['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    return null;
  }

  String _phoneLocal10(String phone) {
    final normalized = _normalizePhone(phone);
    if (normalized.startsWith('+964')) {
      return '0${normalized.substring(4)}';
    }
    if (normalized.startsWith('+20')) {
      return '0${normalized.substring(3)}';
    }
    return normalized;
  }
}
