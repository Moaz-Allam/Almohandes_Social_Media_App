import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/account_type.dart';
import '../../models/profile_form.dart';
import '../../shared/errors/user_error_message.dart';
import '../mappers/supabase_enum_mapper.dart';
import '../session/session_store.dart';
import 'repository_failure.dart';

/// Phone-first auth backed by Supabase + Twilio Verify (mirrors the alqafila
/// project setup). The user flow is:
///
///   signup:   phone → OTP → password → name → [profile questions]
///   login:    phone → password
///
/// We send the signup OTP with `signInWithOtp(shouldCreateUser: true)` so the
/// account is provisioned passwordless on verification; the password screen
/// then patches it in with `updateUser`. Email is optional and never asked at
/// signup — callers can still set it later from profile settings.
abstract interface class AuthRepository {
  bool get isRemoteConfigured;

  /// True if [phone] is already registered. Backed by the `phone_exists`
  /// RPC. Login uses it to fail fast when the number is unknown; signup
  /// uses it to fail fast when the number is taken.
  Future<bool> phoneExists(String phone);

  /// Phone + password login. No SMS sent.
  Future<void> signInWithPassword({
    required String phone,
    required String password,
  });

  /// Sends a signup OTP to [phone] (creating the auth user if needed).
  /// Caller should call [verifySignupOtp] next.
  Future<void> sendSignupOtp({required String phone});

  /// Resend the signup OTP to [phone]. Throws on rate-limit failures so the
  /// caller can show the standard Arabic message.
  Future<void> resendSignupOtp({required String phone});

  /// Verifies the signup OTP. On success Supabase sets the session and the
  /// `handle_new_user` trigger creates the profile row.
  Future<void> verifySignupOtp({
    required String phone,
    required String code,
  });

  /// Sets the password on the currently-signed-in (just-verified) user.
  Future<void> setPasswordForCurrentUser({required String password});

  /// Records the user's full name on the current profile. Called right after
  /// the password step so the remaining profile-question screens can render
  /// the user's name.
  Future<void> setFullNameForCurrentUser({required String fullName});

  /// Finalizes the profile after the city/job questions. Idempotent.
  Future<void> completeSignUp({
    required ProfileForm profile,
    required AccountType accountType,
    required String specialization,
    required String phone,
  });

  /// Sends an OTP to [phone] for password recovery. The number must already
  /// be registered (`shouldCreateUser: false`).
  Future<void> sendPasswordResetOtp({required String phone});

  /// Verifies the password-reset OTP and establishes a session so the caller
  /// can update the password next.
  Future<void> verifyPasswordResetOtp({
    required String phone,
    required String code,
  });

  /// Resets the password for the currently-signed-in user (just verified via
  /// OTP). Requires an active session.
  Future<void> resetPassword({required String newPassword});

  Future<void> signOut();
}

final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({required this.client, required this.sessionStore});

  final SupabaseClient? client;
  final SessionStore sessionStore;

  @override
  bool get isRemoteConfigured => client != null;

  @override
  Future<bool> phoneExists(String phone) async {
    final remote = client;
    if (remote == null) {
      return false;
    }
    final normalized = _normalizePhone(phone);
    if (!_looksLikePhone(normalized)) {
      throw const RepositoryFailure(
        'رقم الهاتف غير صحيح. أعد إدخاله بدون رموز إضافية',
      );
    }
    try {
      final result = await remote.rpc(
        'phone_exists',
        params: {'p_phone': normalized},
      );
      return result == true;
    } catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback: 'تعذر التحقق من الرقم الآن. تحقق من الاتصال وحاول مرة أخرى',
        ),
        error,
      );
    }
  }

  @override
  Future<void> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure(
        'خدمة تسجيل الدخول غير متاحة الآن. تحقق من اتصالك بالإنترنت ثم حاول مرة أخرى',
      );
    }
    if (phone.trim().isEmpty) {
      throw const RepositoryFailure('أدخل رقم هاتفك');
    }
    if (password.isEmpty) {
      throw const RepositoryFailure('أدخل كلمة المرور');
    }
    final normalized = _normalizePhone(phone);
    if (!_looksLikePhone(normalized)) {
      throw const RepositoryFailure(
        'رقم الهاتف غير صحيح. أعد إدخاله بدون رموز إضافية',
      );
    }

    try {
      final auth = await remote.auth.signInWithPassword(
        phone: normalized,
        password: password,
      );
      if (auth.session == null) {
        throw const RepositoryFailure(
          'تعذر إنشاء الجلسة. حاول مرة أخرى',
        );
      }
      await sessionStore.saveSignedIn();
    } on AuthException catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
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
  Future<void> sendSignupOtp({required String phone}) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure(
        'خدمة إنشاء الحساب غير متاحة الآن. تحقق من اتصالك بالإنترنت ثم حاول مرة أخرى',
      );
    }
    final normalized = _normalizePhone(phone);
    if (!_looksLikePhone(normalized)) {
      throw const RepositoryFailure(
        'رقم الهاتف غير صحيح. تحقق من الرقم وأعد المحاولة',
      );
    }
    try {
      await remote.auth.signInWithOtp(
        phone: normalized,
        channel: OtpChannel.sms,
        shouldCreateUser: true,
      );
    } catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'تعذر إرسال رمز التحقق. تحقق من رقم الهاتف ومن الاتصال وحاول مرة أخرى',
        ),
        error,
      );
    }
  }

  @override
  Future<void> resendSignupOtp({required String phone}) async {
    final remote = client;
    if (remote == null) {
      return;
    }
    final normalized = _normalizePhone(phone);
    try {
      await remote.auth.resend(type: OtpType.sms, phone: normalized);
    } catch (error) {
      // Some Supabase versions / states reject `resend` with "Already
      // verified" or no-pending-OTP errors. In that case fall back to a
      // fresh signInWithOtp call so the user still gets a code.
      try {
        await remote.auth.signInWithOtp(
          phone: normalized,
          channel: OtpChannel.sms,
          shouldCreateUser: true,
        );
      } catch (fallbackError) {
        throw RepositoryFailure(
          userErrorMessage(
            fallbackError,
            fallback:
                'تعذر إرسال رمز جديد. انتظر دقيقة ثم حاول مرة أخرى',
          ),
          fallbackError,
        );
      }
    }
  }

  @override
  Future<void> verifySignupOtp({
    required String phone,
    required String code,
  }) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure(
        'خدمة التحقق غير متاحة الآن. تحقق من الاتصال وحاول مرة أخرى',
      );
    }
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      throw const RepositoryFailure('أدخل رمز التحقق المرسل إلى هاتفك');
    }
    if (!RegExp(r'^\d{4,8}$').hasMatch(trimmedCode)) {
      throw const RepositoryFailure('رمز التحقق يجب أن يتكون من أرقام فقط');
    }
    final normalized = _normalizePhone(phone);
    try {
      final auth = await remote.auth.verifyOTP(
        phone: normalized,
        token: trimmedCode,
        type: OtpType.sms,
      );
      if (auth.session == null || auth.user == null) {
        throw const RepositoryFailure(
          'تعذر التحقق من الرمز. اطلب رمزا جديدا ثم حاول مرة أخرى',
        );
      }
    } on AuthException catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'رمز التحقق غير صحيح أو منتهي الصلاحية. اطلب رمزا جديدا',
        ),
        error,
      );
    } catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'تعذر التحقق من الرمز. تحقق من الاتصال أو اطلب رمزا جديدا',
        ),
        error,
      );
    }
  }

  @override
  Future<void> setPasswordForCurrentUser({required String password}) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure(
        'الخدمة غير متاحة الآن. تحقق من الاتصال وحاول مرة أخرى',
      );
    }
    final value = password.trim();
    if (value.isEmpty) {
      throw const RepositoryFailure('أدخل كلمة المرور');
    }
    if (value.length < 6) {
      throw const RepositoryFailure(
        'كلمة المرور قصيرة جدا. استخدم 6 أحرف على الأقل',
      );
    }
    if (remote.auth.currentSession == null) {
      throw const RepositoryFailure(
        'انتهت جلسة التحقق. أعد إدخال رقم هاتفك ورمز التحقق',
      );
    }
    try {
      await remote.auth.updateUser(UserAttributes(password: value));
      await sessionStore.saveSignedIn();
    } catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'تعذر تعيين كلمة المرور. تحقق من الاتصال وحاول مرة أخرى',
        ),
        error,
      );
    }
  }

  @override
  Future<void> setFullNameForCurrentUser({required String fullName}) async {
    final remote = client;
    if (remote == null) {
      return;
    }
    final value = fullName.trim();
    if (value.isEmpty) {
      throw const RepositoryFailure('أدخل اسمك الكامل');
    }
    final userId = remote.auth.currentUser?.id;
    if (userId == null) {
      throw const RepositoryFailure(
        'انتهت جلسة الحساب. أعد تسجيل الدخول',
      );
    }
    try {
      await remote.auth.updateUser(
        UserAttributes(data: {'full_name': value}),
      );
      await remote
          .from('profiles')
          .update({'full_name': value})
          .eq('user_id', userId);
    } catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'تعذر حفظ الاسم. تحقق من الاتصال وحاول مرة أخرى',
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
  }) async {
    final remote = client;
    if (remote == null) {
      await sessionStore.saveSignedIn();
      return;
    }

    final normalizedPhone = _normalizePhone(phone);
    if (profile.fullName.trim().isEmpty) {
      throw const RepositoryFailure('أدخل اسمك الكامل');
    }
    if (!_looksLikePhone(normalizedPhone)) {
      throw const RepositoryFailure(
        'رقم الهاتف غير صحيح. تحقق من الرقم ثم أعد المحاولة',
      );
    }
    if (remote.auth.currentSession == null) {
      throw const RepositoryFailure(
        'انتهت جلسة الحساب. أعد إنشاء الحساب من البداية',
      );
    }
    final userId = remote.auth.currentUser?.id;
    if (userId == null) {
      throw const RepositoryFailure(
        'تعذر تأكيد الجلسة. حاول مرة أخرى',
      );
    }

    try {
      final profileId = await _upsertProfile(
        remote,
        userId: userId,
        profile: profile,
        accountType: accountType,
        phone: normalizedPhone,
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
        // Optional role-detail tables may be absent in stripped-down envs.
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
  Future<void> sendPasswordResetOtp({required String phone}) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure(
        'الخدمة غير متاحة الآن. تحقق من الاتصال وحاول مرة أخرى',
      );
    }
    final normalized = _normalizePhone(phone);
    if (!_looksLikePhone(normalized)) {
      throw const RepositoryFailure(
        'رقم الهاتف غير صحيح. تحقق من الرقم وأعد المحاولة',
      );
    }
    try {
      await remote.auth.signInWithOtp(
        phone: normalized,
        channel: OtpChannel.sms,
        shouldCreateUser: false,
      );
    } catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'تعذر إرسال رمز التحقق. تأكد أن الرقم مسجل ثم حاول مرة أخرى',
        ),
        error,
      );
    }
  }

  @override
  Future<void> verifyPasswordResetOtp({
    required String phone,
    required String code,
  }) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure(
        'الخدمة غير متاحة الآن. تحقق من الاتصال وحاول مرة أخرى',
      );
    }
    final trimmedCode = code.trim();
    if (trimmedCode.isEmpty) {
      throw const RepositoryFailure('أدخل رمز التحقق المرسل إلى هاتفك');
    }
    if (!RegExp(r'^\d{4,8}$').hasMatch(trimmedCode)) {
      throw const RepositoryFailure('رمز التحقق يجب أن يتكون من أرقام فقط');
    }
    final normalized = _normalizePhone(phone);
    try {
      final auth = await remote.auth.verifyOTP(
        phone: normalized,
        token: trimmedCode,
        type: OtpType.sms,
      );
      if (auth.session == null || auth.user == null) {
        throw const RepositoryFailure(
          'تعذر التحقق من الرمز. اطلب رمزا جديدا ثم حاول مرة أخرى',
        );
      }
    } on AuthException catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'رمز التحقق غير صحيح أو منتهي الصلاحية. اطلب رمزا جديدا',
        ),
        error,
      );
    } catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'تعذر التحقق من الرمز. تحقق من الاتصال أو اطلب رمزا جديدا',
        ),
        error,
      );
    }
  }

  @override
  Future<void> resetPassword({required String newPassword}) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure(
        'الخدمة غير متاحة الآن. تحقق من الاتصال وحاول مرة أخرى',
      );
    }
    final value = newPassword.trim();
    if (value.isEmpty) {
      throw const RepositoryFailure('أدخل كلمة المرور الجديدة');
    }
    if (value.length < 6) {
      throw const RepositoryFailure(
        'كلمة المرور قصيرة جدا. استخدم 6 أحرف على الأقل',
      );
    }
    if (remote.auth.currentSession == null) {
      throw const RepositoryFailure(
        'انتهت جلسة التحقق. أعد إدخال رقم هاتفك ورمز التحقق',
      );
    }
    try {
      await remote.auth.updateUser(UserAttributes(password: value));
    } catch (error) {
      throw RepositoryFailure(
        userErrorMessage(
          error,
          fallback:
              'تعذر تعيين كلمة المرور الجديدة. تحقق من الاتصال وحاول مرة أخرى',
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

  Future<String> _upsertProfile(
    SupabaseClient remote, {
    required String userId,
    required ProfileForm profile,
    required AccountType accountType,
    required String phone,
  }) async {
    final role = accountTypeToSupabaseRole(accountType);
    final governorate = governorateToSupabase(profile.location);

    try {
      final profileId = await remote.rpc<String>(
        'complete_signup_profile_for_app',
        params: {
          'p_full_name': profile.fullName,
          'p_email': profile.email.trim(),
          'p_phone': phone,
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

    final profileRow = await _writeProfileWithTables(
      remote,
      userId: userId,
      profile: profile,
      role: role,
      governorate: governorate,
      normalizedPhone: phone,
    );
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
      'role': role,
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
    if (compact.startsWith('+')) {
      return compact;
    }
    if (compact.startsWith('00')) {
      return '+${compact.substring(2)}';
    }
    // Local 07XXXXXXXXX (Iraqi) — assume +964 by default.
    if (RegExp(r'^07[3-9]\d{8}$').hasMatch(compact)) {
      return '+964${compact.substring(1)}';
    }
    // Local 01XXXXXXXXX (Egyptian) — assume +20.
    if (RegExp(r'^01[0125]\d{8}$').hasMatch(compact)) {
      return '+20${compact.substring(1)}';
    }
    return compact;
  }

  bool _looksLikePhone(String normalized) {
    return RegExp(r'^\+\d{8,15}$').hasMatch(normalized);
  }
}
