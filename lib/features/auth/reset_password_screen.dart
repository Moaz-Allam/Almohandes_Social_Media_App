import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/errors/user_error_message.dart';
import '../../shared/widgets/linkedin_logo.dart';
import '../../shared/widgets/linked_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../state/app_scope.dart';
import 'sign_in_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (_isSubmitting) {
      return;
    }
    final password = _password.text.trim();
    if (password.length < 6) {
      _showMessage('كلمة المرور يجب ألا تقل عن 6 أحرف');
      return;
    }
    if (password != _confirmPassword.text.trim()) {
      _showMessage('تأكد من تطابق كلمة المرور');
      return;
    }

    setState(() => _isSubmitting = true);
    final app = AppScope.read(context);
    try {
      await app.repositories.auth.updatePassword(password: password);
      await app.signOut();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('تم تغيير كلمة المرور. سجل الدخول الآن')),
        );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SignInScreen()),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(userErrorMessage(error, fallback: 'تعذر تغيير كلمة المرور'));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: LinkedInLogo(scale: .78),
            ),
            const SizedBox(height: 42),
            Text(
              'تعيين كلمة مرور جديدة',
              style: TextStyle(
                color: context.appText,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أدخل كلمة مرور جديدة لحسابك. بعد الحفظ ستسجل الدخول بها مرة أخرى.',
              style: TextStyle(
                color: context.appMuted,
                fontSize: 15,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 28),
            LinkedTextField(
              label: 'كلمة المرور الجديدة',
              controller: _password,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            LinkedTextField(
              label: 'تأكيد كلمة المرور',
              controller: _confirmPassword,
              obscureText: true,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: _isSubmitting ? 'جاري الحفظ...' : 'حفظ كلمة المرور',
              onPressed: _updatePassword,
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                        (_) => false,
                      ),
              icon: const Icon(Icons.login_outlined, color: AppColors.blue),
              label: const Text(
                'العودة لتسجيل الدخول',
                style: TextStyle(
                  color: AppColors.blue,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
