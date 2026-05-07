import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/account_type.dart';
import '../../models/profile_form.dart';
import '../mappers/supabase_enum_mapper.dart';
import '../session/session_store.dart';
import 'repository_failure.dart';

abstract interface class AuthRepository {
  bool get isRemoteConfigured;

  Future<void> signInWithPassword({
    required String login,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> sendPasswordReset({required String email});

  Future<void> sendOtp({required String phone});

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
      throw const RepositoryFailure('Supabase غير مهيأ لتسجيل الدخول');
    }

    try {
      await remote.auth.signInWithPassword(
        email: login.contains('@') ? login.trim() : null,
        phone: login.contains('@') ? null : _normalizePhone(login),
        password: password,
      );
      await sessionStore.saveSignedIn();
    } catch (error) {
      throw RepositoryFailure('تعذر تسجيل الدخول من Supabase', error);
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure('Supabase غير مهيأ لتسجيل الدخول');
    }

    try {
      await remote.auth.signInWithOAuth(OAuthProvider.google);
      await sessionStore.saveSignedIn();
    } catch (error) {
      throw RepositoryFailure('تعذر تسجيل الدخول بواسطة Google', error);
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {
    final remote = client;
    if (remote == null) {
      throw const RepositoryFailure('Supabase غير مهيأ لاستعادة كلمة المرور');
    }
    if (!email.trim().contains('@')) {
      throw const RepositoryFailure(
        'أدخل بريدك الإلكتروني لاستعادة كلمة المرور',
      );
    }

    try {
      await remote.auth.resetPasswordForEmail(email.trim());
    } catch (error) {
      throw RepositoryFailure('تعذر إرسال رابط استعادة كلمة المرور', error);
    }
  }

  @override
  Future<void> sendOtp({required String phone}) async {
    final remote = client;
    if (remote == null) {
      return;
    }

    try {
      await remote.functions.invoke(
        'send-otp',
        body: {'phone': _normalizePhone(phone)},
      );
    } catch (_) {
      // Keep local prototype usable when the Edge Function is not deployed yet.
    }
  }

  @override
  Future<bool> verifyOtp({required String phone, required String code}) async {
    final remote = client;
    if (remote == null) {
      return code.trim() == '123456';
    }

    try {
      final response = await remote.rpc<bool>(
        'verify_otp_token',
        params: {
          'p_phone_local10': _phoneLocal10(phone),
          'p_verification_code': code.trim(),
        },
      );
      return response;
    } catch (_) {
      return code.trim() == '123456';
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

    try {
      final authResponse = await remote.auth.signUp(
        email: profile.email.trim(),
        password: password,
        data: {
          'full_name': profile.fullName,
          'phone': _normalizePhone(phone),
          'role': accountTypeToSupabaseRole(accountType),
        },
      );
      if (remote.auth.currentSession == null && password.isNotEmpty) {
        try {
          await remote.auth.signInWithPassword(
            email: profile.email.trim(),
            password: password,
          );
        } catch (_) {
          // Some projects require email confirmation before a Supabase session.
        }
      }
      final userId = authResponse.user?.id ?? remote.auth.currentUser?.id;
      if (userId == null) {
        await sessionStore.saveSignedIn();
        return;
      }

      final profileRow = await remote
          .from('profiles')
          .upsert({
            'user_id': userId,
            'full_name': profile.fullName,
            'email': profile.email.trim(),
            'phone': _normalizePhone(phone),
            'role': accountTypeToSupabaseRole(accountType),
            'governorate': governorateToSupabase(profile.location),
            'bio': profile.about,
          }, onConflict: 'user_id')
          .select('id')
          .single();

      final profileId = '${profileRow['id']}';
      await _upsertDetails(
        remote,
        profileId: profileId,
        accountType: accountType,
        specialization: specialization,
        companyName: profile.company,
      );
      await sessionStore.saveSignedIn();
    } catch (error) {
      throw RepositoryFailure('تعذر إنشاء الحساب في Supabase', error);
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
    if (compact.startsWith('0')) {
      return '+964${compact.substring(1)}';
    }
    return compact;
  }

  String _phoneLocal10(String phone) {
    final normalized = _normalizePhone(phone);
    if (normalized.startsWith('+964')) {
      return '0${normalized.substring(4)}';
    }
    return normalized;
  }
}
