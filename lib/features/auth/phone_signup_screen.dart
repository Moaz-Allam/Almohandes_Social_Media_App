import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';
import '../../state/signup_controller.dart';
import 'otp_signup_screen.dart';
import 'phone_login_screen.dart';
import 'widgets/auth_inputs.dart';
import 'widgets/auth_scaffold.dart';

/// Step 1 of the signup wizard — collects the phone number. On submit we
/// (1) check whether the number is already registered (so we can flip the
/// user to the login flow instead of dead-ending on the password screen)
/// and (2) push the OTP screen which kicks off the SMS code.
class PhoneSignupScreen extends StatefulWidget {
  const PhoneSignupScreen({super.key, required this.controller});

  final SignupController controller;

  @override
  State<PhoneSignupScreen> createState() => _PhoneSignupScreenState();
}

class _PhoneSignupScreenState extends State<PhoneSignupScreen> {
  bool _loading = false;
  String? _error;
  bool _alreadyExists = false;

  SignupController get _form => widget.controller;

  bool get _valid => _form.hasValidPhoneNumber && !_loading;

  Future<void> _next() async {
    final phone = _form.fullPhone;
    setState(() {
      _loading = true;
      _error = null;
      _alreadyExists = false;
    });
    try {
      final auth = AppScope.read(context).repositories.auth;
      final exists = await auth.phoneExists(phone);
      if (!mounted) return;
      if (exists) {
        setState(() {
          _alreadyExists = true;
          _error = 'يوجد حساب بهذا الرقم بالفعل. سجّل الدخول بدلا من ذلك';
        });
        return;
      }
      await auth.sendSignupOtp(phone: phone);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpSignupScreen(controller: _form),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _form,
      builder: (context, _) {
        return AuthScaffold(
          icon: Icons.phone_iphone_rounded,
          title: 'أنشئ حسابك',
          subtitle:
              'أدخل رقم هاتفك للبدء. سنرسل لك رمز تحقق عبر رسالة نصية.',
          stepCount: 4,
          currentStep: 1,
          showBack: false,
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'لديك حساب بالفعل؟ ',
                style: TextStyle(color: AppColors.mutedDark, fontSize: 14),
              ),
              GestureDetector(
                onTap: _loading ? null : _goToLogin,
                child: const Text(
                  'تسجيل الدخول',
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
                controller: _form.phoneInput,
                country: _form.country,
                onChanged: (_) {
                  setState(() {
                    _error = null;
                    _alreadyExists = false;
                  });
                },
                onCountryChanged: _form.setCountry,
              ),
              if (_error != null) AuthErrorText(message: _error!),
              if (_alreadyExists)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: TextButton(
                    onPressed: _loading ? null : _goToLogin,
                    child: const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        color: AppColors.primaryGlow,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              AuthPrimaryButton(
                label: 'إرسال رمز التحقق',
                loading: _loading,
                onPressed: _valid ? _next : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
