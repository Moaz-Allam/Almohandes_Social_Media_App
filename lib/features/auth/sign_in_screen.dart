import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../features/home/main_shell.dart';
import '../../shared/widgets/app_snack.dart';
import '../../shared/widgets/linkedin_logo.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/privacy/privacy_policy_dialog.dart';
import '../../state/app_scope.dart';
import 'forgot_password_screen.dart';
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
  bool _obscurePassword = true;

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
    final login = _login.text.trim();
    if (login.isEmpty) {
      AppSnack.error(context, 'أدخل بريدك الإلكتروني أو رقم هاتفك');
      return;
    }
    if (_password.text.isEmpty) {
      AppSnack.error(context, 'أدخل كلمة المرور');
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await AppScope.read(
        context,
      ).signInWithPassword(login: login, password: _password.text);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      AppSnack.error(
        context,
        error,
        fallback:
            'تعذر تسجيل الدخول. تحقق من بيانات الحساب وحاول مرة أخرى',
      );
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

  void _openForgotPassword(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(initialEmail: _login.text),
      ),
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
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.vertical,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: context.appText,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 1),
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: LinearGradient(
                          colors: [
                            context.appPrimary,
                            context.appPrimary.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: context.appPrimary.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: LinkedInLogo(
                          scale: 1.65,
                          showText: false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  Text(
                    'مرحبا بعودتك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appText,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سجل دخولك للمتابعة إلى المهندس',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _AuthTextField(
                    label: 'البريد الإلكتروني أو الهاتف',
                    controller: _login,
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  _AuthTextField(
                    label: 'كلمة المرور',
                    controller: _password,
                    obscureText: _obscurePassword,
                    icon: Icons.lock_outline_rounded,
                    trailing: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: context.appMuted,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _openForgotPassword(context),
                      child: Text(
                        'نسيت كلمة المرور؟',
                        style: TextStyle(
                          color: context.appPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: _isSubmitting ? 'جار تسجيل الدخول...' : 'تسجيل الدخول',
                    onPressed: () => _enterApp(context),
                    isLoading: _isSubmitting,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      InkWell(
                        onTap: () => _join(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Text(
                            'انضم إلينا الآن',
                            style: TextStyle(
                              color: context.appPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        ' ليس لديك حساب؟ ',
                        style: TextStyle(
                          color: context.appMuted,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                  Center(
                    child: TextButton(
                      onPressed: () => showPrivacyPolicyDialog(context),
                      child: Text(
                        'سياسة الخصوصية',
                        style: TextStyle(
                          color: context.appMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.label,
    required this.controller,
    this.obscureText = false,
    required this.icon,
    this.trailing,
  });

  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appBorder.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: Row(
        children: [
          Icon(icon, color: context.appMuted, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              textAlign: TextAlign.right,
              style: TextStyle(color: context.appText, fontSize: 15),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: label,
                hintStyle: TextStyle(
                  color: context.appMuted.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                isDense: true,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
