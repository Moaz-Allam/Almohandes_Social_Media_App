import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/errors/user_error_message.dart';
import '../../state/app_scope.dart';
import '../../state/signup_controller.dart';
import 'name_signup_screen.dart';
import 'widgets/auth_inputs.dart';
import 'widgets/auth_scaffold.dart';

/// Step 3 of signup. The user's phone has just been verified — Supabase
/// already holds a session for the freshly-created account. Here we patch
/// the password in via `updateUser` so future logins can use phone +
/// password instead of OTP.
class PasswordSignupScreen extends StatefulWidget {
  const PasswordSignupScreen({super.key, required this.controller});

  final SignupController controller;

  @override
  State<PasswordSignupScreen> createState() => _PasswordSignupScreenState();
}

class _PasswordSignupScreenState extends State<PasswordSignupScreen> {
  static const _minLength = 6;
  bool _showPwd = false;
  bool _showConfirm = false;
  bool _loading = false;
  String? _error;

  SignupController get _form => widget.controller;

  bool get _valid => _form.hasMatchingPasswords && !_loading;

  Future<void> _submit() async {
    if (_form.password.text.length < _minLength) {
      setState(() => _error = 'كلمة المرور قصيرة جدا. استخدم $_minLength أحرف على الأقل');
      return;
    }
    if (!_form.hasMatchingPasswords) {
      setState(() => _error = 'تأكيد كلمة المرور غير مطابق');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AppScope.read(context).repositories.auth;
      await auth.setPasswordForCurrentUser(password: _form.password.text);
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => NameSignupScreen(controller: _form),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = userErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _form,
      builder: (context, _) {
        return AuthScaffold(
          icon: Icons.shield_outlined,
          title: 'كلمة المرور',
          subtitle:
              'اختر كلمة مرور قوية لحماية حسابك.\nستستخدمها لتسجيل الدخول لاحقا.',
          stepCount: 4,
          currentStep: 3,
          showBack: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _form.password,
                hint: 'كلمة المرور',
                obscure: !_showPwd,
                prefixIcon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _showPwd
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.mutedDark,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showPwd = !_showPwd),
                ),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _form.confirmPassword,
                hint: 'تأكيد كلمة المرور',
                obscure: !_showConfirm,
                prefixIcon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  icon: Icon(
                    _showConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppColors.mutedDark,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'على الأقل $_minLength أحرف',
                  style: TextStyle(
                    color: AppColors.mutedDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_error != null) AuthErrorText(message: _error!),
              const SizedBox(height: 20),
              AuthPrimaryButton(
                label: 'متابعة',
                loading: _loading,
                onPressed: _valid ? _submit : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
