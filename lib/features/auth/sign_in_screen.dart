import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../features/home/main_shell.dart';
import '../../shared/widgets/linkedin_logo.dart';
import '../../shared/widgets/linked_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/social_button.dart';
import '../../state/app_scope.dart';
import 'sign_up_flow_screen.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  Future<void> _enterApp(BuildContext context) async {
    await AppScope.read(context).signIn();
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
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
            const LinkedTextField(label: 'البريد الإلكتروني أو الهاتف'),
            const SizedBox(height: 12),
            const LinkedTextField(label: 'كلمة المرور', obscureText: true),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
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
              label: 'تسجيل الدخول',
              onPressed: () => _enterApp(context),
            ),
            const SizedBox(height: 18),
            SocialButton.google(
              label: 'تسجيل الدخول بواسطة Google',
              onPressed: () => _enterApp(context),
            ),
          ],
        ),
      ),
    );
  }
}
