import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../features/home/main_shell.dart';
import '../../shared/widgets/linkedin_logo.dart';
import '../../shared/widgets/linked_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/privacy/privacy_policy_dialog.dart';
import '../../state/app_scope.dart';
import 'sign_up_flow_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enterApp(BuildContext context) async {
    if (_isSubmitting) {
      return;
    }
    if (_login.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل البريد أو الهاتف وكلمة المرور')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await AppScope.read(
        context,
      ).signInWithPassword(login: _login.text, password: _password.text);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر تسجيل الدخول: $error')));
      return;
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
  }

  Future<void> _resetPassword(BuildContext context) async {
    try {
      await AppScope.read(
        context,
      ).repositories.auth.sendPasswordReset(email: _login.text);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال رابط استعادة كلمة المرور')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر إرسال الرابط: $error')));
    }
  }

  void _join(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const SignUpFlowScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          children: [
            Row(
              children: [
                const LinkedInLogo(scale: .78),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'إغلاق',
                ),
              ],
            ),
            const SizedBox(height: 42),
            Text(
              'تسجيل الدخول',
              style: TextStyle(
                color: context.appText,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('أو ', style: TextStyle(color: context.appMuted)),
                InkWell(
                  onTap: () => _join(context),
                  child: const Text(
                    'انضم إلى المهندس',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            LinkedTextField(
              label: 'البريد الإلكتروني أو الهاتف',
              controller: _login,
            ),
            const SizedBox(height: 12),
            LinkedTextField(
              label: 'كلمة المرور',
              controller: _password,
              obscureText: true,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _resetPassword(context),
                child: const Text(
                  'هل نسيت كلمة المرور؟',
                  style: TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            PrimaryButton(
              label: _isSubmitting ? 'جار تسجيل الدخول...' : 'تسجيل الدخول',
              onPressed: () => _enterApp(context),
              isLoading: _isSubmitting,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => showPrivacyPolicyDialog(context),
              child: const Text('Privacy Policy'),
            ),
          ],
        ),
      ),
    );
  }
}
