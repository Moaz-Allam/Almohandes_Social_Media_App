import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/data/countries.dart';
import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';
import '../../state/signup_controller.dart';
import 'password_login_screen.dart';
import 'phone_signup_screen.dart';
import 'widgets/auth_inputs.dart';
import 'widgets/auth_scaffold.dart';

/// Login step 1 — collect the phone number. We check the number exists
/// (via the phone_exists RPC) before asking for a password, so users on
/// the wrong screen get routed to signup early.
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _controller = TextEditingController();
  Country _country = defaultCountry;
  String _value = '';
  bool _loading = false;
  String? _error;
  bool _missing = false;

  bool get _valid => _value.length >= 7 && !_loading;

  String get _fullPhone {
    final normalized = _value.startsWith('0') ? _value.substring(1) : _value;
    return '${_country.dialCode}$normalized';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    setState(() {
      _loading = true;
      _error = null;
      _missing = false;
    });
    try {
      final auth = AppScope.read(context).repositories.auth;
      final exists = await auth.phoneExists(_fullPhone);
      if (!mounted) return;
      if (!exists) {
        setState(() {
          _missing = true;
          _error = 'لا يوجد حساب بهذا الرقم. أنشئ حسابا جديدا.';
        });
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PasswordLoginScreen(phone: _fullPhone),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToSignup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PhoneSignupScreen(controller: SignupController()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      icon: Icons.phone_iphone_rounded,
      title: 'تسجيل الدخول',
      subtitle: 'أدخل رقم هاتفك المسجَّل لمتابعة الدخول إلى حسابك.',
      stepCount: 2,
      currentStep: 1,
      showBack: false,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'ليس لديك حساب؟ ',
            style: TextStyle(color: AppColors.mutedDark, fontSize: 14),
          ),
          GestureDetector(
            onTap: _loading ? null : _goToSignup,
            child: const Text(
              'أنشئ حسابك',
              style: TextStyle(
                color: AppColors.primaryGlow,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PhoneInputRow(
            controller: _controller,
            country: _country,
            onChanged: (v) => setState(() {
              _value = v;
              _error = null;
              _missing = false;
            }),
            onCountryChanged: (c) => setState(() => _country = c),
          ),
          if (_error != null) AuthErrorText(message: _error!),
          if (_missing)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: TextButton(
                onPressed: _loading ? null : _goToSignup,
                child: const Text(
                  'إنشاء حساب جديد',
                  style: TextStyle(
                    color: AppColors.primaryGlow,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            label: 'متابعة',
            loading: _loading,
            onPressed: _valid ? _next : null,
          ),
        ],
      ),
    );
  }
}
